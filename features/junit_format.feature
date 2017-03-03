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
    And the file "junit/features_World_feature_9.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_World_feature_14.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_World_feature_19.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_World_feature_29.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_World_feature_30.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_World_feature_31.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_World_feature_39.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_World_feature_40.xml" should be a valid document according to "junit.xsd"
    And "junit/features_World_feature_9.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1" errors="1">
          <testcase name="Undefined" time="1" status="undefined">
            <error type="undefined"><![CDATA[And Something new]]></error>
          </testcase>
        </testsuite>
      </testsuites>
      """
    And "junit/features_World_feature_14.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1" errors="1">
          <testcase name="Pending" time="1" status="pending">
            <error type="pending"><![CDATA[And Something not done yet: TODO: write pending definition]]></error>
          </testcase>
        </testsuite>
      </testsuites>
      """
    And "junit/features_World_feature_19.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1" failures="1">
          <testcase name="Failed" time="1" status="failed">
            <failure type="failure"><![CDATA[Then I must have 13: Failed asserting that 14 matches expected '13'.]]></failure>
          </testcase>
        </testsuite>
      </testsuites>
      """
    And "junit/features_World_feature_29.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1" failures="1">
          <testcase name="Passed &amp; Failed Line #29" time="1" status="failed">
            <failure type="failure"><![CDATA[Then I must have 16: Failed asserting that 15 matches expected '16'.]]></failure>
          </testcase>
        </testsuite>
      </testsuites>
      """
    And "junit/features_World_feature_30.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1">
          <testcase name="Passed &amp; Failed Line #30" time="1" status="passed"/>
        </testsuite>
      </testsuites>
      """
    And "junit/features_World_feature_31.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1" failures="1">
          <testcase name="Passed &amp; Failed Line #31" time="1" status="failed">
            <failure type="failure"><![CDATA[Then I must have 32: Failed asserting that 33 matches expected '32'.]]></failure>
          </testcase>
        </testsuite>
      </testsuites>
      """
    And "junit/features_World_feature_39.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1">
          <testcase name="Another Outline Line #39" time="1" status="passed"/>
        </testsuite>
      </testsuites>
      """
    And "junit/features_World_feature_40.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1">
          <testcase name="Another Outline Line #40" time="1" status="passed"/>
        </testsuite>
      </testsuites>
      """
