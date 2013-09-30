%define debug_package %{nil}_bindir}
%define base_install_dir %{_javadir}{%name}

%global bindir %{_bindir}
%global confdir %{_sysconfdir}/%{name}
%global jarpath %{_javadir}
%global lockfile %{_localstatedir}/lock/subsys/%{name}
%global logdir %{_localstatedir}/log/%{name}
%global piddir %{_localstatedir}/run/%{name}
%global sysconfigdir %{_sysconfdir}/sysconfig

Name:           logstash
Version:        1.2.1
Release:        1%{?dist}
Summary:        A tool for managing events and logs

Group:          System Environment/Daemons
License:        ASL 2.0
URL:            http://logstash.net
Source0:        https://logstash.objects.dreamhost.com/release/%{name}-%{version}-flatjar.jar
Source1:        logstash.wrapper
Source2:        logstash.logrotate
Source3:        logstash.init
Source4:        logstash.sysconfig
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      x86_64 

#Requires:       jre7
Requires:       jpackage-utils

Requires(post): chkconfig initscripts
Requires(pre):  chkconfig initscripts
Requires(pre):  shadow-utils

%description
A tool for managing events and logs.

%prep
%build

%install
rm -rf $RPM_BUILD_ROOT

# JAR file
%{__mkdir} -p %{buildroot}%{_javadir}
%{__install} -p -m 644 %{SOURCE0} %{buildroot}%{jarpath}/%{name}.jar

# Config
%{__mkdir} -p %{buildroot}%{confdir}

# Wrapper script
%{__mkdir} -p %{buildroot}%{_bindir}
%{__install} -m 755 %{SOURCE1} %{buildroot}%{bindir}/%{name}

%{__sed} -i \
   -e "s|@@@NAME@@@|%{name}|g" \
   -e "s|@@@JARPATH@@@|%{jarpath}|g" \
   %{buildroot}%{bindir}/%{name}

# Logs
%{__mkdir} -p %{buildroot}%{logdir}
%{__install} -D -m 644 %{SOURCE2} %{buildroot}%{_sysconfdir}/logrotate.d/%{name}

# Misc
%{__mkdir} -p %{buildroot}%{piddir}

# sysconfig and init
%{__mkdir} -p %{buildroot}%{_initddir}
%{__mkdir} -p %{buildroot}%{_sysconfdir}/sysconfig
%{__install} -m 755 %{SOURCE3} %{buildroot}%{_initddir}/%{name}
%{__install} -m 644 %{SOURCE4} %{buildroot}%{sysconfigdir}/%{name}

%{__sed} -i \
   -e "s|@@@NAME@@@|%{name}|g" \
   -e "s|@@@DAEMON@@@|%{bindir}|g" \
   -e "s|@@@CONFDIR@@@|%{confdir}|g" \
   -e "s|@@@LOCKFILE@@@|%{lockfile}|g" \
   -e "s|@@@LOGDIR@@@|%{logdir}|g" \
   -e "s|@@@PIDDIR@@@|%{piddir}|g" \
   %{buildroot}%{_initddir}/%{name}

%{__sed} -i \
   -e "s|@@@NAME@@@|%{name}|g" \
   -e "s|@@@CONFDIR@@@|%{confdir}|g" \
   -e "s|@@@LOGDIR@@@|%{logdir}|g" \
   -e "s|@@@PLUGINDIR@@@|%{_datadir}|g" \
   %{buildroot}%{sysconfigdir}/%{name}

%pre
# create logstash group
if ! getent group logstash >/dev/null; then
        groupadd -r logstash
fi

# create logstash user
if ! getent passwd logstash >/dev/null; then
        useradd -r -g logstash -d %{_javadir}/%{name} \
            -s /sbin/nologin -c "You know, for search" logstash
fi

%post
/sbin/chkconfig --add logstash

%preun
if [ $1 -eq 0 ]; then
  /sbin/service logstash stop >/dev/null 2>&1
  /sbin/chkconfig --del logstash
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
# JAR file
%{_javadir}/%{name}.jar

# Config
%config(noreplace) %{confdir}/

# Wrapper script
%{bindir}/*


# Logrotate
%config(noreplace) %{_sysconfdir}/logrotate.d/%{name}

# Sysconfig and init
%{_initddir}/%{name}
%config(noreplace) %{sysconfigdir}/*

%defattr(-,%{name},%{name},-)
%dir %{logdir}/
%dir %{piddir}/

%changelog
* Mon Sep 16 2013 sjir@basefarm.se 1.2.1
- Updated version to the new 1.2.1
- Removed everything related to plugins as it no longer works.

* Wed Sep 04 2013 sjir@basefarm.se 1.2.0
- Updated version to the new 1.2.0.
- Fixed a problem with the init.d script not working correctly.

* Fri Jun 14 2013 sjir@basefarm.se 1.1.13-1
- Updated version to the new 1.1.13-1 and fixed some minor issues with directory structure.

* Fri May 6 2013 sjir@basefarm.se 1.1.10-3
- Changed from logstash flatjar to the monolith as flatjar is not working correctly yet.

* Fri Apr 19 2013 sjir@basefarm.se 1.1.10-2
- Fixed a bug

* Fri Apr 19 2013 sjir@basefarm.se 1.1.10-1
- Added fixes to support RHEL6
- Update logstash version to 1.1.10

* Sun Mar 17 2013 Richard Pijnenburg <richard@ispavailability.com> - 1.1.9-2
- Update init script
- Create patterns dir in correct place

* Sat Feb  1 2013 Richard Pijnenburg <richard@ispavailability.com> - 1.1.9-1
- Update to latest stable release.
- New init script

* Fri May  4 2012 Maksim Horbul <max@gorbul.net> - 1.1.0-1
- Initial package
