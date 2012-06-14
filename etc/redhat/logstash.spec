# logstash.spec  - 1.1.0 Final package for nexage
# package information
# copies logstash files and init.d script
###############################################################

Name:		logstash
Version:	1.1.0
Release:	nxg.1%{?dist}
Summary:	logstash is a tool for managing events and logs

Group:		System/Logging
License:	ASL 2.0
URL:		http://logstash.net/
Source0:	http://semicomplete.com/files/logstash/logstash-%{version}-monolithic.jar
Source1:	logstash
Source2:	logstash-null.conf
Source3:	$RPM_SOURCE_DIR/lib
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch

Requires:	jdk

%description
logstash is a tool for managing events and logs. You can use it to collect logs, parse them, and store them for later use (like, for searching). Speaking of searching, logstash comes with a web interface for searching and drilling into all of your logs.

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.


%prep

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/%{name} $RPM_BUILD_ROOT/%{_sysconfdir}/init.d
install %{SOURCE0} $RPM_BUILD_ROOT/opt/%{name}
/usr/java/default/bin/jar uf $RPM_BUILD_ROOT/opt/%{name}/%{name}-%{version}-monolithic.jar -C %{SOURCE3} logstash
install -m 755 %{SOURCE1} $RPM_BUILD_ROOT/%{_sysconfdir}/init.d/%{name}
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/%{name}.d
install %{SOURCE2} $RPM_BUILD_ROOT/%{_sysconfdir}/%{name}.d
ln -s /opt/%{name}/%{name}-%{version}-monolithic.jar $RPM_BUILD_ROOT/opt/%{name}/%{name}-monolithic.jar

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%config %{_sysconfdir}/%{name}.d/logstash-null.conf
/opt/%{name}/%{name}-%{version}-monolithic.jar
/opt/%{name}/%{name}-monolithic.jar
%{_sysconfdir}/init.d/%{name}

%changelog
* Tue Apr 17 2012 Bob W.
	- Added mechanism to update original jar with Nexage filter code in Ruby (from SOURCES/lib/logstash/...)
	- Added logstash-null.conf file to do nothing without throwing an error
* Mon Apr 16 2012 Bob W.
	- Took SPEC file from github gist <https://gist.github.com/2228905> and integrated it. Took out rc.d in paths.
* Tue Mar 09 2012 Derek
        -Generalized and removed from starting automatically
* Tue Feb 14 2012 Derek
        -Initial creation
