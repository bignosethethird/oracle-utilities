/*
------------------------------------------------------------------------
$Header: utl/extprocs/hostcmd/hostcmd.c 1.1 2004/11/30 12:24:32GMT apenney PRODUCTION  $
------------------------------------------------------------------------
Creates the Unix Shared Object library hostcmd.so,
or the Win32 dll, hostcmd.dll

This library allows the calling of external procedure from Oracle RDBMS.

Usage:
Build and install using the installation script in the Install directory.
This will create an external library for calling from Oracle PL/SQL.

Security implications:
Unix:
  This function allows the calling of any host command that the Unix user 'oracle',
  or whatever the user name who owns the oracle application, has access to.
  E.g. anyone who has permission to execute this shared library, will be able
  to execute any command they like as user 'oracle'.

Win32:
  What security?

------------------------------------------------------------------------
*/

#ifdef _WIN32
  #include <windows.h>
  #define DLL_EXPORT __declspec(dllexport)
#else
  #include <string.h>
  #define DLL_EXPORT
#endif

int DLL_EXPORT hostcmd(char * cmd)
{
  return system(cmd);
}

