<?php

$finder = Symfony\CS\Finder::create()
    ->in(__DIR__.'/src');

return Symfony\CS\Config::create()
    ->setUsingCache(true)
    ->fixers([
        'align_equals',
        'align_double_arrow',
        'ordered_use',
        'short_array_syntax',
        '-psr0',
    ])
    ->finder($finder);