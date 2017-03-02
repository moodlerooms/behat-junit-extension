<?php

namespace Moodlerooms\BehatJUnitExtension;

use Behat\Testwork\ServiceContainer\Extension as ExtensionInterface;
use Behat\Testwork\ServiceContainer\ExtensionManager;
use Symfony\Component\Config\Definition\Builder\ArrayNodeDefinition;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Definition;

class Extension implements ExtensionInterface
{
    /**
     * process.
     *
     * @param ContainerBuilder $container
     */
    public function process(ContainerBuilder $container)
    {
    }

    /**
     * getConfigKey.
     *
     * @return string
     */
    public function getConfigKey()
    {
        return 'moodleroomsJUnit';
    }

    /**
     * initialize.
     *
     * @param ExtensionManager $extensionManager
     */
    public function initialize(ExtensionManager $extensionManager)
    {
    }

    /**
     * configure.
     *
     * @param ArrayNodeDefinition $builder
     */
    public function configure(ArrayNodeDefinition $builder)
    {
        $builder->children()->scalarNode('outputDir')->defaultValue('build/tests');
    }

    /**
     * load.
     *
     * @param ContainerBuilder $container
     * @param array            $config
     */
    public function load(ContainerBuilder $container, array $config)
    {
        $definition = new Definition('Moodlerooms\\BehatJUnitExtension\\Formatter');
        $definition->addArgument($config['outputDir']);

        $container->setDefinition('moodlerooms.junit.formatter', $definition)
            ->addTag('output.formatter');
    }
}
