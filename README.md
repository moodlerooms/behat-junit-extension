# Introduction

todo

# Install

Install with Composer:

    composer require --dev moodlerooms/behat-junit-extension

# Usage

Activate the extension by specifying its class in your `behat.yml`:

```yaml
default:
    suites:
    ...

    extensions:
        BehatJUnitExtension:
            outputDir: %paths.base%/build/tests
    ...
```

Be sure to call Behat with the formatter:

    behat -f junit

# Configuration

* `outputDir` - Directory to store all of the JUnit XML files.

# Credits

Heavily inspired by [behat-junit-formatter](https://github.com/j-arnaiz/behat-junit-formatter).