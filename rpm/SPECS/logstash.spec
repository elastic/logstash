# do not repack jar files
%define __os_install_post %{nil}
%define __jar_repack %{nil}
# do not build debug packages
%define debug_package %{nil}
%define base_install_dir /usr/share/%{name}

Name:           logstash
Version:        1.1.9
Release:        2%{?dist}
Summary:        Logstash is a tool for managing events and logs.

Group:          System Environment/Daemons
License:        Apache License, Version 2.0
URL:            http://logstash.net
Source0:        https://logstash.objects.dreamhost.com/release/%{name}-%{version}-monolithic.jar
Source1:        logstash.init
Source2:        logstash.logrotate
Source3:        logstash.sysconfig
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch

Requires:       jre >= 1.6.0

Requires(post): chkconfig initscripts
Requires(pre):  chkconfig initscripts
Requires(pre):  shadow-utils

%description
Logstash is a tool for managing events and logs

%prep
true

%build
true

%install
rm -rf $RPM_BUILD_ROOT

%{__mkdir} -p %{buildroot}%{base_install_dir}
%{__install} -m 755 %{SOURCE0} %{buildroot}%{base_install_dir}/logstash.jar

# plugins & patterns
%{__mkdir} -p %{buildroot}%{base_install_dir}/plugins
%{__mkdir} -p %{buildroot}%{_sysconfdir}/%{name}/patterns

# logs
%{__mkdir} -p %{buildroot}%{_localstatedir}/log/%{name}
%{__install} -D -m 644 %{SOURCE2} %{buildroot}%{_sysconfdir}/logrotate.d/logstash

# sysconfig and init
%{__mkdir} -p %{buildroot}%{_sysconfdir}/rc.d/init.d
%{__mkdir} -p %{buildroot}%{_sysconfdir}/sysconfig
%{__install} -m 755 %{SOURCE1} %{buildroot}%{_sysconfdir}/rc.d/init.d/logstash
%{__install} -m 644 %{SOURCE3} %{buildroot}%{_sysconfdir}/sysconfig/logstash

%{__mkdir} -p %{buildroot}%{_localstatedir}/run/logstash
%{__mkdir} -p %{buildroot}%{_localstatedir}/lock/subsys/logstash
%{__mkdir} -p %{buildroot}%{base_install_dir}/tmp

%pre
# create logstash group
if ! getent group logstash >/dev/null; then
        groupadd -r logstash
fi

# create logstash user
if ! getent passwd logstash >/dev/null; then
        useradd -r -g logstash -d %{base_install_dir} \
            -s /sbin/nologin -c "Logstash" logstash
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
%dir %{base_install_dir}
%dir %{base_install_dir}/plugins
%dir %{_sysconfdir}/%{name}/patterns

%{_sysconfdir}/rc.d/init.d/logstash
%{_sysconfdir}/logrotate.d/logstash

%{base_install_dir}/logstash.jar

%config(noreplace) %{_sysconfdir}/sysconfig/logstash

%defattr(-,logstash,logstash,-)
%{_localstatedir}/run/logstash
%{base_install_dir}/tmp
%dir %{_localstatedir}/log/logstash

%changelog
* Sun Mar 17 2013 Richard Pijnenburg <richard@ispavailability.com> - 1.1.9-2
- Update init script
- Create patterns dir in correct place

* Sat Feb  1 2013 Richard Pijnenburg <richard@ispavailability.com> - 1.1.9-1
- Update to latest stable release.
- New init script

* Fri May  4 2012 Maksim Horbul <max@gorbul.net> - 1.1.0-1
- Initial package
