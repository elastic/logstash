import subprocess
import os
from .constants import image, version

try:
    version += '-%s' % os.environ['STAGING_BUILD_NUM']
except KeyError:
    pass
