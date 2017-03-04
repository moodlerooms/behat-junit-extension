# Introduction

Behat extension that reports with the JUnit format and is compatible with Moodle reruns.

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
        Moodlerooms\BehatJUnitExtension\Extension:
            baseDir: /path/to/moodle
    ...
```

Be sure to call Behat with the formatter:

    behat -f moodle_junit -o reports_dir

# Configuration

* `baseDir` - (Optional) Just shortens JUnit XML file names.

# Credits

Heavily inspired by [behat-junit-formatter](https://github.com/j-arnaiz/behat-junit-formatter).