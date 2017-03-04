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
use Behat\Behat\Hook\Scope\StepScope;
use Behat\Behat\Output\Node\Printer\Helper\ResultToStringConverter;
use Behat\Behat\Tester\Result\StepResult;
use Behat\Testwork\Call\CallResult;
use Behat\Testwork\Call\CallResults;
use Behat\Testwork\Counter\Timer;
use Behat\Testwork\EventDispatcher\Event\AfterSetup;
use Behat\Testwork\Exception\ExceptionPresenter;
use Behat\Testwork\Hook\Call\HookCall;
use Behat\Testwork\Hook\Tester\Setup\HookedSetup;
use Behat\Testwork\Hook\Tester\Setup\HookedTeardown;
use Behat\Testwork\Output\Formatter as FormatterInterface;
use Behat\Testwork\Tester\Result\ExceptionResult;
use Behat\Testwork\Tester\Result\TestResult;
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
     * Keeps track of setup errors.
     *
     * @var array
     */
    private $hookErrors = [];

    /**
     * @param string                  $baseDir
     * @param ExceptionPresenter      $exceptionPresenter
     * @param ResultToStringConverter $converter
     */
    public function __construct($baseDir, ExceptionPresenter $exceptionPresenter, ResultToStringConverter $converter)
    {
        $this->printer            = new Printer();
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

            // All of these events find setup errors.

            // I think these have been ruled out as not necessary.
            //SuiteTested::AFTER_SETUP => ['afterSetup', -50],
            //ExerciseCompleted::AFTER_SETUP => ['afterSetup', -50],
            //FeatureTested::AFTER_SETUP => ['afterSetup', -50],
            //ScenarioTested::AFTER_SETUP => ['afterSetup', -50],
            //ExampleTested::AFTER_SETUP => ['afterSetup', -50],

            // These are a maybe.
            //BackgroundTested::AFTER_SETUP => ['afterSetup', -50],
            //OutlineTested::AFTER_SETUP => ['afterSetup', -50],

            StepTested::AFTER_SETUP => ['afterSetup', -50],
        ];
    }

    /**
     * Capture scenario title before it starts.
     *
     * This is not called for outline/examples.
     *
     * @param BeforeScenarioTested $event
     */
    public function beforeScenario(BeforeScenarioTested $event)
    {
        $this->initBeforeScenario($event, $event->getScenario()->getTitle());
    }

    /**
     * Capture outline title before it starts.
     *
     * @param BeforeOutlineTested $event
     */
    public function beforeOutline(BeforeOutlineTested $event)
    {
        $this->currentOutlineTitle = $event->getOutline()->getTitle();
    }

    /**
     * Capture example line number and combine it with outline title.
     *
     * @param BeforeScenarioTested $event
     */
    public function beforeExample(BeforeScenarioTested $event)
    {
        $this->initBeforeScenario($event, $this->currentOutlineTitle.' Line #'.$event->getScenario()->getLine());
    }

    /**
     * Catch setup errors.
     *
     * @param AfterSetup $event
     */
    public function afterSetup(AfterSetup $event)
    {
        $setup = $event->getSetup();
        if (!$setup->isSuccessful() && $setup instanceof HookedSetup) {
            $this->handleHookCalls($setup->getHookCallResults(), 'setup');
        }
    }

    /**
     * Look for errors after the step has been executed.
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

            default:
                // This captures errors in tear down hooks, like @AfterStep.
                $tearDown = $event->getTeardown();
                if (!$tearDown->isSuccessful() && $tearDown instanceof HookedTeardown) {
                    $this->handleHookCalls($tearDown->getHookCallResults(), 'teardown');
                }
        }
    }

    /**
     * After the scenario, gather remaining errors/stats and write the JUnit XML file.
     *
     * @param AfterScenarioTested $event
     */
    public function afterScenario(AfterScenarioTested $event)
    {
        $this->testCaseTimer->stop();

        $this->currentTestCase->setTime($this->formatTime($this->testCaseTimer));
        $this->currentTestCase->setAttribute('status', $this->converter->convertResultToString($event->getTestResult()));

        if (!empty($this->hookErrors)) {
            foreach ($this->hookErrors as $error) {
                list($type, $message) = $error;

                $data = $this->currentDocument->createCDATASection($message);
                $this->currentTestCase->addFailure(null, $type)->appendChild($data);
            }
            $this->hookErrors = [];
        }

        // Don't think these cause any real problems, but fail to pass the junit.xsd validation.
        $this->currentTestCase->removeAttribute('errors');
        $this->currentTestCase->removeAttribute('failures');

        $this->printer->setFileName($this->fileName($event));
        $this->printer->write($this->currentDocument->saveXML());
    }

    /**
     * Initialize JUnit document pieces and start the timer.
     *
     * @param ScenarioTested $event
     * @param string         $name
     */
    private function initBeforeScenario(ScenarioTested $event, $name)
    {
        $name = implode(' ', array_map(function ($l) {
            return trim($l);
        }, explode("\n", $name)));

        $this->currentDocument = new Document();

        $this->currentTestSuite = $this->currentDocument->addTestSuite();
        $this->currentTestSuite->setName($event->getFeature()->getTitle());

        $this->currentTestCase = $this->currentTestSuite->addTestCase();
        $this->currentTestCase->setName($name);

        $this->testCaseTimer->start();
    }

    /**
     * Generate a unique file name for the scenario.
     *
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

    /**
     * Searches hooks for errors.
     *
     * @param CallResults $results
     * @param string      $messageType
     */
    private function handleHookCalls(CallResults $results, $messageType)
    {
        /** @var CallResult $hookCallResult */
        foreach ($results as $hookCallResult) {
            if ($hookCallResult->hasException()) {
                /** @var HookCall $call */
                $call  = $hookCallResult->getCall();
                $scope = $call->getScope();

                $message = '';
                if ($scope instanceof StepScope) {
                    $message .= $scope->getStep()->getKeyword().' '.$scope->getStep()->getText().': ';
                }
                $message .= $this->exceptionPresenter->presentException($hookCallResult->getException());

                // We don't add these to currentTestCase because it may not have been setup yet.
                $this->hookErrors[] = [$messageType, $message];
            }
        }
    }
}
