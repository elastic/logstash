from subprocess import run
import pytest
from .constants import container_name, version
import docker

docker_engine = docker.from_env()


def pytest_addoption(parser):
    """Customize testinfra with config options via cli args"""
    # Let us specify which docker-compose-(image_flavor).yml file to use
    parser.addoption('--image-flavor', action='store', default='full',
                     help='Docker image flavor; the suffix used in docker-compose-<flavor>.yml')


@pytest.fixture(scope='session', autouse=True)
def start_container():
    image = 'docker.elastic.co/logstash/logstash-%s:%s' % (pytest.config.getoption('--image-flavor'), version)
    docker_engine.containers.run(image, name=container_name, detach=True, stdin_open=False)


def pytest_unconfigure(config):
    container = docker_engine.containers.get(container_name)
    container.stop()
    container.remove()
