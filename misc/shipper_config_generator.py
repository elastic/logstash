#!/usr/bin/env python
"""
generate logstash shipper configuration file
"""
import logging
import os
import re
import subprocess
import sys
import httplib
import socket

from subprocess import Popen, CalledProcessError
from subprocess import STDOUT, PIPE

logging.getLogger("shipper_config_generator").setLevel(logging.DEBUG)

PWD = os.path.dirname(os.path.realpath(__file__))


def _get_first_ip_addr_by_sock():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect(('baidu.com', 80))
    ip_addr = sock.getsockname()[0]
    return ip_addr
   
def _get_first_ip_addr_by_http():
    conn = httplib.HTTPConnection(host='ifconfig.me', port=80, timeout=3.0)
    conn.request('GET', '/ip')
    resp = conn.getresponse()
    ip_addr = resp.read().strip()
    return ip_addr
  
def get_first_ip_addr():
    try:
        return _get_first_ip_addr_by_http()
    except Exception:
        return _get_first_ip_addr_by_sock()


# this function copy from Python 2.7 subprocess.py::check_output
def func_check_output(*popenargs, **kwargs):
    r"""Run command with arguments and return its output as a byte string.

    If the exit code was non-zero it raises a CalledProcessError.  The
    CalledProcessError object will have the return code in the returncode
    attribute and output in the output attribute.

    The arguments are the same as for the Popen constructor.  Example:

    >>> check_output(["ls", "-l", "/dev/null"])
    'crw-rw-rw- 1 root root 1, 3 Oct 18  2007 /dev/null\n'

    The stdout argument is not allowed as it is used internally.
    To capture standard error in the result, use stderr=STDOUT.

    >>> check_output(["/bin/sh", "-c",
    ...               "ls -l non_existent_file ; exit 0"],
    ...              stderr=STDOUT)
    'ls: non_existent_file: No such file or directory\n'
    """
    if 'stdout' in kwargs:
        raise ValueError('stdout argument not allowed, it will be overridden.')
    process = Popen(stdout=PIPE, *popenargs, **kwargs)
    output, unused_err = process.communicate()
    retcode = process.poll()
    if retcode:
        cmd = kwargs.get("args")
        if cmd is None:
            cmd = popenargs[0]
        raise CalledProcessError(retcode, cmd, output=output)
    return output


def check_output(*popenargs, **kwargs):
    if sys.version_info[0] == 2 and sys.version_info[1] < 7:
        _check_output = func_check_output
    else:
        _check_output = subprocess.check_output

    return _check_output(*popenargs, **kwargs)

def check_output_wrapper(s):
    return check_output(s, shell=True).strip()

"""
Usage: 
s = "ps aux | grep redis-server | grep -v 'grep' | awk '{print $NF}'"
print check_output(s, shell=True)
print check_output_wrapper(s)
"""


def get_redis_log_full_path_list():
    log_full_path_list = set()
    ls_rds_inst = "ps aux | grep redis-server | grep -v 'grep' | awk '{print $NF}'"
    
    for config_path in check_output_wrapper(ls_rds_inst).split():
        if not os.path.exists(config_path):
           sys.stderr.write('[redis] %s not exists or not a absolute path \n' % config_path)
           continue

        with open(config_path) as f:
            for line in f.readlines():
                if line.startswith('logfile'):
                    splits = line.split()
                    if len(splits) == 2:
                        key, val = splits[0], splits[1].strip()
                        if os.path.exists(val):
                            log_full_path_list.add(val)
    return log_full_path_list

def get_php_fpm_log_full_path_list():
    error_log_full_path_list = set()
    slow_log_full_path_list = set()

    get_config_abs_path = "ps aux |grep php-fpm |grep master | awk '{print $NF}' | tr -d '()'"

    for config_path in check_output_wrapper(get_config_abs_path).split():
        config_path = config_path.strip().strip('"').strip("'")
        if not config_path:
            continue
        if not os.path.exists(config_path):
            sys.stderr.write('[php-fpm] %s not exits or not a absolute path \n' % config_path)
            continue

        s = file(config_path).read()
        pool_name_list = [i for i in re.findall('^\[(?P<pool_name>\w+)\]', s, re.MULTILINE)
                    if i != 'global']
        if len(pool_name_list) != 1:
            sys.stderr.write("[php-fpm] %s php-fpm log detector doesn't supports multiple pool \n" % config_path)
            continue
        pool_name = pool_name_list[0]

        with open(config_path) as f:
            for line in f.readlines():
                if line.startswith('error_log'):
                    splits = line.split('=')
                    error_log = splits[-1].strip().strip(';').replace('$pool',  pool_name)
                    if not os.path.exists(error_log):
                        sys.stderr.write('[php-fpm] %s not exits or not a absolute path \n' % error_log)
                        continue
                    error_log_full_path_list.add(error_log)

                if line.startswith('slowlog'):
                    splits = line.split('=')
                    slow_log = splits[-1].strip().strip(';').replace('$pool', pool_name)
                    if not os.path.exists(slow_log):
                        sys.stderr.write('[php-fpm] %s not exits or not a absolute path \n' % slow_log)
                        continue
                    slow_log_full_path_list.add(slow_log)

    return error_log_full_path_list, slow_log_full_path_list


def get_mysql_log_full_path_list():
    error_list = set()
    slow_list = set()

    for pid in check_output_wrapper('pidof mysqld').split():
        pid = pid.strip()
        meta = {
            'config-file': None,
            'error-log': None,
            'slow-log': None,
            }
        for line in check_output_wrapper('ps -p %s -f | grep %s' % (pid, pid)).split():
            line = line.strip().replace('_', '-')
            if line.startswith("--defaults-file"):
                meta['config-file'] = line.replace('--defaults-file=', '')
            elif line.startswith('--log-error'):
                meta['error-log'] = line.replace('--log-error=', '')
            elif line.startswith('--slow-query-log-file'):
                meta['slow-log'] = line.replace('--slow-query-log-file=', '')

        if meta['config-file']:
            with open(meta['config-file']) as f:
                for line in f.readlines():
                    line = line.replace('_', '-')
                    if line.startswith('slow-query-log-file'):
                        meta['slow-log'] = line.replace('slow-query-log-file', '').replace('=', '').strip()
                    elif line.startswith('log-error'):
                        meta['error-log'] = line.replace('error-log', '').replace('=', '').strip()                    

        if meta['slow-log']:
            slow_list.add(meta['slow-log'])
        if meta['error-log']:
            error_list.add(meta['error-log'])
            
    return list(error_list), list(slow_list)


TEMPLATE_INPUT_FILE = """  file {{
    charset => 'UTF-8'
    type => '{logstash_type}'
    path => '{file_path}'
    format => 'plain'
  }}
"""

def generte_input_file_block(file_path, logstash_type):
     return TEMPLATE_INPUT_FILE.format(
          logstash_type=logstash_type,
          file_path=file_path, 
          )

CONFIG_TEMPLATE_FILTER_PHP = """  multiline {{
    type => 'php-error'
    pattern => '^(\s|#|Stack)'
    what => 'previous'
  }}

  multiline {{
    type => 'php-fpm-slow'
    pattern => '^$'
    what => 'previous'
    negate => true
  }}

  grok {{
    type => 'php-error'
    patterns_dir => '{patterns_dir}'
    pattern => '%{{PHP_ERROR_LOG}}'
    singles => true
  }}

  grok {{
    type => 'php-fpm-error'
    patterns_dir => '{patterns_dir}'
    pattern => '%{{PHP_FPM_ERROR_LOG}}'
    singles => true
  }}

  grok {{
    type => 'php-fpm-slow'
    patterns_dir => '{patterns_dir}'
    pattern => '%{{PHP_FPM_SLOW_LOG}}'
    singles => true
  }}
"""

CONFIG_TEMPLATE_INPUTS = """input {{
  stdin {{
    type => 'stdin-type'
  }}

  tcp {{
    type => 'test-pattern'
    host => '127.0.0.1'
    port => 9100
    mode => server
    debug => true
    format => plain
  }}

{input_blocks}

}}

"""

CONFIG_TEMPLATE_FILTERS_PREFIX = """filter {{
"""
CONFIG_TEMPLATE_FILTERS_SUFFIX = """  date {{
    match => ['timestamp', 'dd-MMM-YYYY HH:mm:ss z', 'dd-MMM-YYYY HH:mm:ss']
  }}

  mutate {{
    replace => ["@source_host", "DEFAULT_SOURCE_HOST"]
  }}

}}

"""

CONFIG_TEMPLATE_FILTER_MYSQL = """  multiline {{
    type => 'mysql-slow'
    pattern => "^# User@Host: "
    negate => true
    what => previous
  }}

  multiline {{
    type => 'mysql-error'
    what => previous
    pattern => '^\s'
  }}

  grok {{
    type => 'mysql-error'
    patterns_dir => '{patterns_dir}'
    pattern => '%{{MYSQL_ERROR_LOG}}'
  }}

  grep {{
    type => 'mysql-slow'
    match => [ "@message", "^# Time: " ]
    negate => true
  }}

  grok {{
    type => 'mysql-slow'
    singles => true
    patterns_dir => '{patterns_dir}'
    pattern => [
      "%{{MYSQL_SLOW_FROM}}",
      "%{{MYSQL_SLOW_STAT}}",
      "%{{MYSQL_SLOW_TIMESTAMP}}",
      "%{{MYSQL_SLOW_DB}}",
      "%{{MYSQL_SLOW_QUERY}}"
     ]
   }}

  date {{
    type => 'mysql-slow'
    match => ['timestamp', 'YYddMM HH:mm:ss']
  }}

  mutate {{
    type => 'mysql-slow'
    remove => "timestamp"
  }}
"""

CONFIG_TEMPLATE_FILTER_REDIS = """  grok {{
    type => 'redis'
    patterns_dir => '{patterns_dir}'
    pattern => '%{{REDISLOG_FIXED}}'
  }}
"""


CONFIG_TEMPLATE_OUTPUTS = """output {{
#  stdout {{
#    debug => true
#    debug_format => "json"
#  }}

  redis {{
    host => "{output_redis_host}"
    port => {output_redis_port}
    data_type => "list"
    key => "logstash"
  }}

{output_blocks}
}}
"""

def main():
    output_redis_host = '10.20.60.85'
    output_redis_port = 6380
    patterns_dir = '/usr/local/logstash/patterns'


    chunks = []
    for path in get_redis_log_full_path_list():
        sys.stdout.write("%s %s found \n" % ("redis", path))
        chunks.append(generte_input_file_block(path, "redis"))

    error_list, slow_list = get_php_fpm_log_full_path_list()
    for path in error_list:
        sys.stdout.write("%s %s found \n" % ("php-fpm-error", path))
        chunks.append(generte_input_file_block(path, "php-fpm-error"))
    for path in slow_list:
        sys.stdout.write("%s %s found \n" % ("php-fpm-slow", path))
        chunks.append(generte_input_file_block(path, "php-fpm-slow"))

    error_list, slow_list = get_mysql_log_full_path_list()
    for path in error_list:
        sys.stdout.write("%s %s found \n" % ("mysql-error", path))
        chunks.append(generte_input_file_block(path, "mysql-error"))
    for path in slow_list:
        sys.stdout.write("%s %s found \n" % ("mysql-slow", path))
        chunks.append(generte_input_file_block(path, "mysql-slow"))    
    input_blocks = '\n'.join(chunks)

    t = CONFIG_TEMPLATE_INPUTS + \
        CONFIG_TEMPLATE_FILTERS_PREFIX + \
        CONFIG_TEMPLATE_FILTER_REDIS + \
        '\n' + \
        CONFIG_TEMPLATE_FILTER_MYSQL + \
        '\n' + \
        CONFIG_TEMPLATE_FILTER_PHP + \
        CONFIG_TEMPLATE_FILTERS_SUFFIX + \
        CONFIG_TEMPLATE_OUTPUTS

    output_blocks = ""
    content = t.format(
         input_blocks=input_blocks, 
        output_blocks=output_blocks,
        patterns_dir=patterns_dir,
         output_redis_host=output_redis_host,
         output_redis_port=output_redis_port,
         )

    ip_addr = None
    try:
        ip_addr = get_first_ip_addr()
    except Exception:
        pass
    if ip_addr:
        content = content.replace("DEFAULT_SOURCE_HOST", ip_addr)

    FOLDER_PARENT = os.path.dirname(PWD)
    save_to_prefix = os.path.join(FOLDER_PARENT, "conf")
    save_to = os.path.join(save_to_prefix, "shipper-dev.conf")
    
    # save_to = os.path.join(PWD, 'shipper.conf')
    
    with open(save_to, 'w') as f:
         f.write(content)
    sys.stdout.write("save to %s \n" % save_to)

if __name__ == '__main__':
    main()
