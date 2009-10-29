%define logstash_dir /opt/logstash

Name:		logstash
Version:	0.3.4
Release:	1
License:	BSD
URL:		http://code.google.com/p/logstash
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(id -u)
Source0:	http://code.google.com/p/logstash/downloads/%{name}-%{version}.tar.gz
Summary:	Centralized log indexing and searching
Group:		Applications/System
BuildArch:      noarch

%description
LogStash

%package server
Summary:        LogStash parsing, indexing, and searching server
Requires:	%{name}-libs = %{version}-%{release}
Requires:       grok-ruby
Requires(pre):  shadow-utils
Requires(post): chkconfig
Requires(preun): chkconfig
Requires(preun): initscripts
Requires(postun): initscripts
Group:		Applications/System

%description server
LogStash daemon.

%package libs
Summary:	LogStash common Ruby libraries
Requires:	ruby >= 1.8.5
Group:		Applications/System

%description libs
LogStash Ruby libraries.

%package agent
Summary:	LogStash log file collection agent
Requires:	%{name}-libs = %{version}-%{release}
Requires(post): chkconfig
Requires(preun): chkconfig
Requires(preun): initscripts
Requires(postun): initscripts
Group:		Applications/System

%description agent
LogStash file collection agent.

%package web
Summary:	LogStash web query interface
Requires:	%{name}-libs = %{version}-%{release}
Group:		Applications/System

%description web
LogStash web query interface.

%prep
%setup

%install
rm -rf %{buildroot}
%{__mkdir_p} %{buildroot}%{logstash_dir}
%{__mkdir_p} %{buildroot}/etc/init.d
%{__mkdir_p} %{buildroot}/etc/sysconfig
%{__mkdir_p} %{buildroot}/var/logstash
tar cf - bin etc/*.yaml lib patterns web \
  | (cd %{buildroot}%{logstash_dir} && tar xf -)
install -c etc/redhat/logstash %{buildroot}/etc/init.d/logstash
install -c etc/redhat/logstash-agent %{buildroot}/etc/init.d/logstash-agent
install -c etc/redhat/logstash.sysconfig %{buildroot}/etc/sysconfig/logstash
install -c etc/redhat/logstash-agent.sysconfig \
        %{buildroot}/etc/sysconfig/logstash-agent

%clean
rm -rf $RPM_BUILD_ROOT

%files libs
%defattr(-, root, root, 0755)
%{logstash_dir}/lib/config
%{logstash_dir}/lib/log.rb
%{logstash_dir}/lib/logs.rb
%{logstash_dir}/lib/net/client.rb
%{logstash_dir}/lib/net/clients
%{logstash_dir}/lib/net/common.rb
%{logstash_dir}/lib/net/messagepacket.rb
%{logstash_dir}/lib/net/message.rb
%{logstash_dir}/lib/net/server.rb
%{logstash_dir}/lib/net/socket.rb
%{logstash_dir}/lib/net/messages
%{logstash_dir}/lib/net.rb
%{logstash_dir}/lib/program.rb
%{logstash_dir}/lib/util.rb

%files server
%defattr(-, root, root, 0755)
/etc/init.d/logstash
%config(noreplace) /etc/sysconfig/logstash
%{logstash_dir}/bin/list_log_keys.rb
%{logstash_dir}/bin/list_log_types.rb
%{logstash_dir}/bin/logstashd
%{logstash_dir}/bin/search.rb
%{logstash_dir}/lib/log
%{logstash_dir}/lib/net/servers
%{logstash_dir}/patterns
%config(noreplace) %{logstash_dir}/etc/logstashd.yaml
%defattr(-, logstash, logstash, 0775)
/var/logstash

%files agent
%defattr(-, root, root, 0755)
/etc/init.d/logstash-agent
%config(noreplace) /etc/sysconfig/logstash-agent
%{logstash_dir}/bin/logstash-agent
%{logstash_dir}/lib/net/clients/agent.rb
%{logstash_dir}/lib/file/tail/since.rb
%config(noreplace) %{logstash_dir}/etc/logstash-agent.yaml

%files web
%defattr(-, root, root, 0755)
%{logstash_dir}/web

%pre server
getent group logstash &>/dev/null || groupadd -r logstash
getent passwd logstash &>/dev/null || \
  useradd -r -g logstash -d %{logstash_dir} -s /sbin/nologin \
    -c "LogStash Daemon" logstash

%post server
/sbin/chkconfig --add logstash

%post agent
/sbin/chkconfig --add logstash-agent

%preun server
if [ "$1" = 0 ] ; then
  /sbin/service logstash stop &>/dev/null
  /sbin/chkconfig --del logstash &>/dev/null || true
fi

%preun agent
if [ "$1" = 0 ] ; then
  /sbin/service logstash-agent stop &>/dev/null
  /sbin/chkconfig --del logstash-agent &>/dev/null || true
fi

%postun server
if [ "$1" -ge 1 ]; then
  /sbin/service logstash condrestart &>/dev/null || true
fi

%postun agent
if [ "$1" -ge 1 ]; then
  /sbin/service logstash-agent condrestart &>/dev/null || true
fi

%changelog
* Mon Oct 19 2009 Pete Fritchman <petef@databits.net> - 0.3.0-1
- Initial packaging
