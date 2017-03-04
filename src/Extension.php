<?php

namespace Moodlerooms\BehatJUnitExtension;

use Behat\Testwork\Exception\ServiceContainer\ExceptionExtension;
use Behat\Testwork\ServiceContainer\Extension as ExtensionInterface;
use Behat\Testwork\ServiceContainer\ExtensionManager;
use Symfony\Component\Config\Definition\Builder\ArrayNodeDefinition;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Definition;
use Symfony\Component\DependencyInjection\Reference;

class Extension implements ExtensionInterface
{
    const RESULT_TO_STRING_CONVERTER_ID = 'output.node.printer.result_to_string';

    /**
     * {@inheritdoc}
     */
    public function process(ContainerBuilder $container)
    {
    }

    /**
     * {@inheritdoc}
     */
    public function getConfigKey()
    {
        return 'moodleroomsJUnit';
    }

    /**
     * {@inheritdoc}
     */
    public function initialize(ExtensionManager $extensionManager)
    {
    }

    /**
     * {@inheritdoc}
     */
    public function configure(ArrayNodeDefinition $builder)
    {
        $builder->children()->scalarNode('baseDir')->defaultValue('%paths.base%');
    }

    /**
     * {@inheritdoc}
     */
    public function load(ContainerBuilder $container, array $config)
    {
        $definition = new Definition('Behat\Behat\Output\Node\Printer\Helper\ResultToStringConverter');
        $container->setDefinition(self::RESULT_TO_STRING_CONVERTER_ID, $definition);

        $definition = new Definition('Moodlerooms\\BehatJUnitExtension\\Formatter', [
            $config['baseDir'],
            new Reference(ExceptionExtension::PRESENTER_ID),
            new Reference(self::RESULT_TO_STRING_CONVERTER_ID),
        ]);

        $container->setDefinition('moodlerooms.junit.formatter', $definition)
            ->addTag('output.formatter');
    }
}
