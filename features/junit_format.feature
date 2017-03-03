Feature: JUnit Formatter
  In order integrate with other development tools
  As a developer
  I need to be able to generate a JUnit-compatible report

  Background:
    Given a file named "behat.yml" with:
    """
    default:
      extensions:
        Moodlerooms\BehatJUnitExtension\Extension:
          outputDir: %paths.base%/junit
    """

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

  Scenario: Multiple Features
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
      }
      """
    And a file named "features/adding_feature_1.feature" with:
      """
      Feature: Adding Feature 1
        In order to add number together
        As a mathematician
        I want, something that acts like a calculator

        Scenario: Adding 4 to 10
          Given I have entered 10
          When I add 4
          Then I must have 14
      """
    And a file named "features/adding_feature_2.feature" with:
      """
      Feature: Adding Feature 2
        In order to add number together
        As a mathematician
        I want, something that acts like a calculator

        Scenario: Adding 8 to 10
          Given I have entered 10
          When I add 8
          Then I must have 18
      """
    When I run "behat --no-colors -f moodle_junit"
    And the file "junit/features_adding_feature_1_feature_6.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_adding_feature_2_feature_6.xml" should be a valid document according to "junit.xsd"
    And "junit/features_adding_feature_1_feature_6.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="Adding Feature 1" tests="1">
          <testcase name="Adding 4 to 10" time="1" status="passed"/>
        </testsuite>
      </testsuites>
      """
    And "junit/features_adding_feature_2_feature_6.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="Adding Feature 2" tests="1">
          <testcase name="Adding 8 to 10" time="1" status="passed"/>
        </testsuite>
      </testsuites>
      """

  Scenario: Multiline titles
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php

      use Behat\Behat\Context\Context;

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
           * @When /I (add|subtract) the value (\d+)/
           */
          public function iAddOrSubstact($op, $num) {
              if ($op == 'add')
                $this->value += $num;
              elseif ($op == 'subtract')
                $this->value -= $num;
          }
      }
      """
    And a file named "features/World.feature" with:
      """
      Feature: World consistency
        In order to maintain stable behaviors
        As a features developer
        I want, that "World" flushes between scenarios

        Background:
          Given I have entered 10

        Scenario: Adding some interesting
                  value
          Then I must have 10
          And I add the value 6
          Then I must have 16

        Scenario: Subtracting
                  some
                  value
          Then I must have 10
          And I subtract the value 6
          Then I must have 4
      """
    When I run "behat --no-colors -f moodle_junit"
    Then it should pass with no output
    And the file "junit/features_world_feature_9.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_world_feature_15.xml" should be a valid document according to "junit.xsd"
    And "junit/features_world_feature_9.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1">
          <testcase name="Adding some interesting value" time="1" status="passed"/>
        </testsuite>
      </testsuites>
      """
    And "junit/features_world_feature_15.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1">
          <testcase name="Subtracting some value" time="1" status="passed"/>
        </testsuite>
      </testsuites>
      """

  Scenario: Multiple suites
    Given a file named "features/bootstrap/SmallKidContext.php" with:
      """
      <?php

      use Behat\Behat\Context\Context;

      class SmallKidContext implements Context
      {
          protected $strongLevel;

          /**
           * @Given I am not strong
           */
          public function iAmNotStrong() {
              $this->strongLevel = 0;
          }

          /**
           * @When /I eat an apple/
           */
          public function iEatAnApple() {
              $this->strongLevel += 2;
          }

          /**
           * @Then /I will be stronger/
           */
          public function iWillBeStronger() {
              PHPUnit_Framework_Assert::assertNotEquals(0, $this->strongLevel);
          }
      }
      """
    And a file named "features/bootstrap/OldManContext.php" with:
    """
      <?php

      use Behat\Behat\Context\Context;

      class OldManContext implements Context
      {
          protected $strongLevel;

          /**
           * @Given I am not strong
           */
          public function iAmNotStrong() {
              $this->strongLevel = 0;
          }

          /**
           * @When /I eat an apple/
           */
          public function iEatAnApple() { }

          /**
           * @Then /I will be stronger/
           */
          public function iWillBeStronger() {
              PHPUnit_Framework_Assert::assertNotEquals(0, $this->strongLevel);
          }
      }
      """
    And a file named "features/apple_eating_smallkid.feature" with:
      """
      Feature: Apple Eating
        In order to be stronger
        As a small kid
        I want to get stronger from eating apples

        Background:
          Given I am not strong

        Scenario: Eating one apple
          When I eat an apple
          Then I will be stronger
      """
    And a file named "features/apple_eating_oldmen.feature" with:
    """
      Feature: Apple Eating
        In order to be stronger
        As an old man
        I want to get stronger from eating apples

        Background:
          Given I am not strong

        Scenario: Eating one apple
          When I eat an apple
          Then I will be stronger
      """
    And a file named "behat.yml" with:
      """
      default:
        suites:
          small_kid:
            contexts: [SmallKidContext]
            filters:
              role: small kid
            path: %paths.base%/features
          old_man:
            contexts: [OldManContext]
            path: %paths.base%/features
            filters:
              role: old man
        extensions:
          Moodlerooms\BehatJUnitExtension\Extension:
            outputDir: %paths.base%/junit
      """
    When I run "behat --no-colors -f moodle_junit"
    Then it should fail with no output
    And the file "junit/features_apple_eating_smallkid_feature_9.xml" should be a valid document according to "junit.xsd"
    And the file "junit/features_apple_eating_oldmen_feature_9.xml" should be a valid document according to "junit.xsd"
    And "junit/features_apple_eating_smallkid_feature_9.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="Apple Eating" tests="1">
          <testcase name="Eating one apple" time="1" status="passed"/>
        </testsuite>
      </testsuites>
      """
    And "junit/features_apple_eating_oldmen_feature_9.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="Apple Eating" tests="1" failures="1">
          <testcase name="Eating one apple" time="1" status="failed">
            <failure type="failure"><![CDATA[Then I will be stronger: Failed asserting that 0 is not equal to 0.]]></failure>
          </testcase>
        </testsuite>
      </testsuites>
      """

  Scenario: Report skipped testcases
    Given a file named "features/bootstrap/FeatureContext.php" with:
    """
      <?php

      use Behat\Behat\Context\Context,
          Behat\Behat\Tester\Exception\PendingException;

      class FeatureContext implements Context
      {
          private $value;

          /**
           * @BeforeScenario
           */
          public function setup() {
            throw new \Exception();
          }

          /**
           * @Given /I have entered (\d+)/
           * @Then /^I must have (\d+)$/
           */
          public function action($num)
          {
          }
      }
      """
    And a file named "features/World.feature" with:
    """
      Feature: World consistency
        In order to maintain stable behaviors
        As a features developer
        I want, that "World" flushes between scenarios

        Background:
          Given I have entered 10

        Scenario: Skipped
          Then I must have 10
      """
    When I run "behat --no-colors -f moodle_junit"
    And "junit/features_world_feature_9.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1">
          <testcase name="Skipped" time="1" status="skipped"/>
        </testsuite>
      </testsuites>
      """
    And the file "junit/features_world_feature_9.xml" should be a valid document according to "junit.xsd"

  Scenario: Stop on Failure
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
      }
      """
    And a file named "features/World.feature" with:
      """
      Feature: World consistency
        In order to maintain stable behaviors
        As a features developer
        I want, that "World" flushes between scenarios

        Background:
          Given I have entered 10

        Scenario: Failed
          When I add 4
          Then I must have 13
      """
    When I run "behat --no-colors -f moodle_junit"
    Then it should fail with no output
    And "junit/features_world_feature_9.xml" file xml should be like:
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
    And the file "junit/features_world_feature_9.xml" should be a valid document according to "junit.xsd"

  Scenario: Aborting due invalid output path
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php

      use Behat\Behat\Context\Context,
          Behat\Behat\Tester\Exception\PendingException;

      class FeatureContext implements Context
      {
      }
      """
    And a file named "junit.txt" with:
      """
      """
    And a file named "behat.yml" with:
    """
    default:
      extensions:
        Moodlerooms\BehatJUnitExtension\Extension:
          outputDir: %paths.base%/junit.txt
    """
    When I run "behat --no-colors -f junit -o junit.txt"
    Then it should fail with:
      """
      [Behat\Testwork\Output\Exception\BadOutputPathException]
        Directory expected for the `outputDir` option, but a filename was given.
      """

  Scenario: Include BeforeStep Failures
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php

      use Behat\Behat\Context\Context,
          Behat\Behat\Tester\Exception\PendingException;

      class FeatureContext implements Context
      {
          private $value;

          /**
           * @BeforeStep
           */
          public function setup() {
            throw new \Exception('failure');
          }

          /**
           * @Given /I have entered (\d+)/
           * @Then /^I must have (\d+)$/
           */
          public function action($num)
          {
          }
      }
      """
    And a file named "features/World.feature" with:
      """
      Feature: World consistency
        In order to maintain stable behaviors
        As a features developer
        I want, that "World" flushes between scenarios

        Background:
          Given I have entered 10

        Scenario: Failed
          Then I must have 10

      """
    When I run "behat --no-colors -f moodle_junit"
    And "junit/features_world_feature_9.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1" failures="1">
          <testcase name="Failed" time="1" status="failed">
            <failure type="setup"><![CDATA[Given I have entered 10: failure (Exception)]]></failure>
          </testcase>
        </testsuite>
      </testsuites>
      """
    And the file "junit/features_world_feature_9.xml" should be a valid document according to "junit.xsd"

  Scenario: Include AfterStep Failures
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php

      use Behat\Behat\Context\Context,
          Behat\Behat\Tester\Exception\PendingException;

      class FeatureContext implements Context
      {
          private $value;

          /**
           * @AfterStep
           */
          public function setup() {
            throw new \Exception('failure');
          }

          /**
           * @Given /I have entered (\d+)/
           * @Then /^I must have (\d+)$/
           */
          public function action($num)
          {
          }
      }
      """
    And a file named "features/World.feature" with:
      """
      Feature: World consistency
        In order to maintain stable behaviors
        As a features developer
        I want, that "World" flushes between scenarios

        Background:
          Given I have entered 10

        Scenario: Failed
          Then I must have 10

      """
    When I run "behat --no-colors -f moodle_junit"
    And "junit/features_world_feature_9.xml" file xml should be like:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <testsuites>
        <testsuite name="World consistency" tests="1" failures="1">
          <testcase name="Failed" time="1" status="failed">
            <failure type="teardown"><![CDATA[Given I have entered 10: failure (Exception)]]></failure>
          </testcase>
        </testsuite>
      </testsuites>
      """
    And the file "junit/features_world_feature_9.xml" should be a valid document according to "junit.xsd"