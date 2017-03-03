<?php

namespace Moodlerooms\BehatJUnitExtension;

use Behat\Behat\EventDispatcher\Event\AfterScenarioTested;
use Behat\Behat\EventDispatcher\Event\AfterStepTested;
use Behat\Behat\EventDispatcher\Event\BeforeOutlineTested;
use Behat\Behat\EventDispatcher\Event\BeforeScenarioTested;
use Behat\Behat\EventDispatcher\Event\ExampleTested;
use Behat\Behat\EventDispatcher\Event\OutlineTested;
use Behat\Behat\EventDispatcher\Event\ScenarioTested;
use Behat\Behat\EventDispatcher\Event\StepTested;
use Behat\Behat\Output\Node\Printer\Helper\ResultToStringConverter;
use Behat\Behat\Tester\Result\StepResult as TestResult;
use Behat\Behat\Tester\Result\StepResult;
use Behat\Testwork\Counter\Timer;
use Behat\Testwork\Exception\ExceptionPresenter;
use Behat\Testwork\Output\Formatter as FormatterInterface;
use Behat\Testwork\Tester\Result\ExceptionResult;
use N98\JUnitXml\Document;
use N98\JUnitXml\TestCaseElement;
use N98\JUnitXml\TestSuiteElement;

class Formatter implements FormatterInterface
{
    /**
     * @var Printer
     */
    private $printer;

    /**
     * Base directory from where Behat is being run.
     *
     * @var string
     */
    private $baseDir;

    /**
     * @var ExceptionPresenter
     */
    private $exceptionPresenter;

    /**
     * @var ResultToStringConverter
     */
    private $converter;

    /**
     * @var array
     */
    private $parameters = [];

    /**
     * @var Document
     */
    private $currentDocument;

    /**
     * @var TestSuiteElement
     */
    private $currentTestSuite;

    /**
     * @var TestCaseElement
     */
    private $currentTestCase;

    /**
     * @var Timer
     */
    private $testCaseTimer;

    /**
     * @var string
     */
    private $currentOutlineTitle;

    /**
     * @param string                  $outputDir
     * @param string                  $baseDir
     * @param ExceptionPresenter      $exceptionPresenter
     * @param ResultToStringConverter $converter
     */
    public function __construct($outputDir, $baseDir, ExceptionPresenter $exceptionPresenter, ResultToStringConverter $converter)
    {
        $this->printer            = new Printer($outputDir);
        $this->testCaseTimer      = new Timer();
        $this->baseDir            = $baseDir;
        $this->exceptionPresenter = $exceptionPresenter;
        $this->converter          = $converter;
    }

    /**
     * {@inheritdoc}
     */
    public function getName()
    {
        return 'moodle_junit';
    }

    /**
     * {@inheritdoc}
     */
    public function getDescription()
    {
        return 'Creates a JUnit XML files';
    }

    /**
     * {@inheritdoc}
     */
    public function setParameter($name, $value)
    {
        $this->parameters[$name] = $value;
    }

    /**
     * {@inheritdoc}
     */
    public function getParameter($name)
    {
        return isset($this->parameters[$name]) ? $this->parameters[$name] : null;
    }

    /**
     * {@inheritdoc}
     */
    public function getOutputPrinter()
    {
        return $this->printer;
    }

    /**
     * {@inheritdoc}
     */
    public static function getSubscribedEvents()
    {
        return [
            ScenarioTested::BEFORE => ['beforeScenario', -50],
            ScenarioTested::AFTER  => ['afterScenario', -50],
            StepTested::AFTER      => ['afterStep', -50],
            OutlineTested::BEFORE  => ['beforeOutline', -50],
            ExampleTested::BEFORE  => ['beforeExample', -50],
            ExampleTested::AFTER   => ['afterScenario', -50],
        ];
    }

    /**
     * beforeScenario.
     *
     * @param BeforeScenarioTested $event
     */
    public function beforeScenario(BeforeScenarioTested $event)
    {
        $this->initBeforeScenario($event, $event->getScenario()->getTitle());
    }

    /**
     * beforeOutline.
     *
     * @param BeforeOutlineTested $event
     */
    public function beforeOutline(BeforeOutlineTested $event)
    {
        $this->currentOutlineTitle = $event->getOutline()->getTitle();
    }

    /**
     * beforeExample.
     *
     * @param BeforeScenarioTested $event
     */
    public function beforeExample(BeforeScenarioTested $event)
    {
        $this->initBeforeScenario($event, $this->currentOutlineTitle.' Line #'.$event->getScenario()->getLine());
    }

    /**
     * afterStep.
     *
     * @param AfterStepTested $event
     */
    public function afterStep(AfterStepTested $event)
    {
        $message = $event->getStep()->getKeyword().' '.$event->getStep()->getText();

        $testResult = $event->getTestResult();
        if ($testResult instanceof ExceptionResult && $testResult->hasException()) {
            $message .= ': '.$this->exceptionPresenter->presentException($testResult->getException());
        }

        switch ($testResult->getResultCode()) {
            case TestResult::FAILED:
                $data = $this->currentDocument->createCDATASection($message);
                $this->currentTestCase->addFailure(null, 'failure')->appendChild($data);
                break;

            case TestResult::PENDING:
                $data = $this->currentDocument->createCDATASection($message);
                $this->currentTestCase->addError(null, 'pending')->appendChild($data);

                break;

            case StepResult::UNDEFINED:
                $data = $this->currentDocument->createCDATASection($message);
                $this->currentTestCase->addError(null, 'undefined')->appendChild($data);
                break;
        }
    }

    public function afterScenario(AfterScenarioTested $event)
    {
        $this->testCaseTimer->stop();

        $this->currentTestCase->setTime($this->formatTime($this->testCaseTimer));
        $this->currentTestCase->setAttribute('status', $this->converter->convertResultToString($event->getTestResult()));

        // Don't think these cause any real problems, but fail to pass the junit.xsd validation.
        $this->currentTestCase->removeAttribute('errors');
        $this->currentTestCase->removeAttribute('failures');

        $this->printer->setFileName($this->fileName($event));
        $this->printer->write($this->currentDocument->saveXML());
    }

    private function initBeforeScenario(ScenarioTested $event, $name)
    {
        $name = implode(' ', array_map(function ($l) {
            return trim($l);
        }, explode("\n", $name)));

        $this->currentDocument  = new Document();
        $this->currentTestSuite = $this->currentDocument->addTestSuite();
        $this->currentTestSuite->setName($event->getFeature()->getTitle());
        $this->currentTestCase = $this->currentTestSuite->addTestCase();
        $this->currentTestCase->setName($name);
        $this->testCaseTimer->start();
    }
    
    /**
     * @param AfterScenarioTested $event
     *
     * @return string
     */
    private function fileName(AfterScenarioTested $event)
    {
        $name = str_replace($this->baseDir, '', $event->getFeature()->getFile());
        $name = $name.'_'.$event->getScenario()->getLine();

        return strtolower(trim(preg_replace('/[^[:alnum:]_]+/', '_', $name), '_'));
    }

    /**
     * Really this just provides a trick for testing (round up to 1 second).
     *
     * @param Timer $timer
     *
     * @return float|int
     */
    private function formatTime(Timer $timer)
    {
        $time = \round($timer->getTime(), 3);

        if ($time < 1) {
            return 1;
        }

        return $time;
    }
}
