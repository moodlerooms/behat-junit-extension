# Introduction

Behat extension that reports with the JUnit format and is compatible with Moodle reruns.

# Install

Install with Composer:

    composer require --dev open-lms-open-source/behat-junit-extension

# Usage

Activate the extension by specifying its class in your `behat.yml`:

```yaml
default:
    suites:
    ...

    extensions:
        BehatJUnitExtension\Extension:
            baseDir: /path/to/moodle
    ...
```

This is how you would do the above via Moodle's config file:

```php
$CFG->behat_config = [
    'default' => [
        'extensions' => [
            'BehatJUnitExtension\Extension' => [
                'baseDir' => __DIR__,
            ]
        ]
    ],
];
```

Be sure to call Behat with the formatter:

    behat -f moodle_junit -o reports_dir

# Configuration

* `baseDir` - (Optional) Just shortens JUnit XML file names.

# Credits

Heavily inspired by:

* [Behat's](https://github.com/Behat/Behat) own JUnit formatter.
* [behat-junit-formatter](https://github.com/j-arnaiz/behat-junit-formatter)
