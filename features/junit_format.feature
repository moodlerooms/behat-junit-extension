Feature: JUnit Formatter
  In order integrate with other development tools
  As a developer
  I need to be able to generate a JUnit-compatible report

  Scenario: Normal Scenario's
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php

      use Behat\Behat\Context\Context,
          Behat\Behat\Tester\Exception\PendingException;

      class FeatureContext implements Context
      {
          private $value;

          /**
           * @Given /I have entered (\d+)/
           */
          public function iHaveEntered($num) {
              $this->value = $num;
          }

          /**
           * @Then /I must have (\d+)/
           */
          public function iMustHave($num) {
              PHPUnit_Framework_Assert::assertEquals($num, $this->value);
          }

          /**
           * @When /I add (\d+)/
           */
          public function iAdd($num) {
              $this->value += $num;
          }

          /**
           * @When /^Something not done yet$/
           */
          public function somethingNotDoneYet() {
              throw new PendingException();
          }
      }
      """
    And a file named "behat.yml" with:
    """
    default:
      extensions:
        Moodlerooms\BehatJUnitExtension\Extension:
            outputDir: %paths.base%/junit
    """
    And a file named "features/World.feature" with:
      """
      Feature: World consistency
        In order to maintain stable behaviors
        As a features developer
        I want, that "World" flushes between scenarios

        Background:
          Given I have entered 10

        Scenario: Undefined
          Then I must have 10
          And Something new
          Then I must have 10

        Scenario: Pending
          Then I must have 10
          And Something not done yet
          Then I must have 10

        Scenario: Failed
          When I add 4
          Then I must have 13

        Scenario Outline: Passed & Failed
          When I add <value>
          Then I must have <result>

          Examples:
            | value | result |
            |  5    | 16     |
            |  10   | 20     |
            |  23   | 32     |

      Scenario Outline: Another Outline
        When I add <value>
        Then I must have <result>

        Examples:
          | value | result |
          | 5     | 15     |
          | 10    | 20     |
      """
    When I run "behat --no-colors -f moodle_junit --snippets-for=FeatureContext --snippets-type=regex"
    Then it should fail with:
      """
      --- FeatureContext has missing steps. Define them with these snippets:

          /**
           * @Then /^Something new$/
           */
          public function somethingNew()
          {
              throw new PendingException();
          }
      """
    And "junit/todo.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites name="default">
        <testsuite name="World consistency" tests="8" skipped="0" failures="3" errors="2">
          <testcase name="Undefined" status="undefined">
            <error message="And Something new" type="undefined"/>
          </testcase>
          <testcase name="Pending" status="pending">
            <error message="And Something not done yet: TODO: write pending definition" type="pending"/>
          </testcase>
          <testcase name="Failed" status="failed">
            <failure message="Then I must have 13: Failed asserting that 14 matches expected '13'."/>
          </testcase>
          <testcase name="Passed &amp; Failed #1" status="failed">
            <failure message="Then I must have 16: Failed asserting that 15 matches expected '16'."/>
          </testcase>
          <testcase name="Passed &amp; Failed #2" status="passed"/>
          <testcase name="Passed &amp; Failed #3" status="failed">
            <failure message="Then I must have 32: Failed asserting that 33 matches expected '32'."/>
          </testcase>
          <testcase name="Another Outline #1" status="passed"/>
          <testcase name="Another Outline #2" status="passed"/>
        </testsuite>
      </testsuites>
      """
    And the file "junit/todo.xml" should be a valid document according to "junit.xsd"
