%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%undefine _disable_source_fetch

Name:           perl-Convert-TNEF
Version:        0.18
Release:        1.eFa%{?dist}
Summary:        Perl module to read TNEF files
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            https://metacpan.org/pod/Convert::TNEF
Source0:        https://cpan.metacpan.org/authors/id/D/DO/DOUGW/Convert-TNEF-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
TNEF stands for Transport Neutral Encapsulation Format, and if you've ever
been unfortunate enough to receive one of these files as an email
attachment you may want to use this module.

%prep
%setup -q -n Convert-TNEF-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} install

find %{buildroot} -name .packlist -exec %{__rm} {} \;
find %{buildroot} -name perllocal.pod -exec %{__rm} {} \;
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null \;
%{_fixperms} %{buildroot}/*

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc Changes README
%{perl_vendorlib}/*
%{_mandir}/man3/*.3pm*

%changelog
* Sun Aug 30 2026 EFA-NG Project <https://efa-ng.space.ua> - 0.18-1
- Built for EFA-NG EL10
