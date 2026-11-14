# SPDX-License-Identifier: GPL-3.0-or-later
#
# Creates a Start menu shortcut that carries the AppUserModelID of the probe.
# Windows shows the toasts of an unpackaged app only if such a shortcut exists.
# Usage: .\make_shortcut.ps1 -Target <exe> -Aumid <id> -LinkPath <file.lnk>

param([string]$Target, [string]$Aumid, [string]$LinkPath)

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;

namespace ProbeShortcut {
  [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
  class CShellLink {}

  [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("000214F9-0000-0000-C000-000000000046")]
  interface IShellLinkW {
    void GetPath(IntPtr pszFile, int cch, IntPtr pfd, uint fFlags);
    void GetIDList(out IntPtr ppidl);
    void SetIDList(IntPtr pidl);
    void GetDescription(IntPtr pszName, int cch);
    void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
    void GetWorkingDirectory(IntPtr pszDir, int cch);
    void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
    void GetArguments(IntPtr pszArgs, int cch);
    void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
    void GetHotkey(out short pwHotkey);
    void SetHotkey(short wHotkey);
    void GetShowCmd(out int piShowCmd);
    void SetShowCmd(int iShowCmd);
    void GetIconLocation(IntPtr pszIconPath, int cch, out int piIcon);
    void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
    void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
    void Resolve(IntPtr hwnd, uint fFlags);
    void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
  }

  [StructLayout(LayoutKind.Sequential, Pack = 4)]
  struct PropertyKey {
    public Guid fmtid;
    public uint pid;
  }

  [StructLayout(LayoutKind.Explicit)]
  struct PropVariant {
    [FieldOffset(0)] public ushort vt;
    [FieldOffset(8)] public IntPtr pointer;
  }

  [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
  interface IPropertyStore {
    void GetCount(out uint cProps);
    void GetAt(uint iProp, out PropertyKey pkey);
    void GetValue(ref PropertyKey key, out PropVariant pv);
    void SetValue(ref PropertyKey key, ref PropVariant pv);
    void Commit();
  }

  public static class Maker {
    public static void Create(string target, string aumid, string linkPath) {
      var link = (IShellLinkW)new CShellLink();
      link.SetPath(target);
      link.SetWorkingDirectory(System.IO.Path.GetDirectoryName(target));
      var store = (IPropertyStore)link;
      var key = new PropertyKey {
        fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), pid = 5 };
      var value = new PropVariant { vt = 31, pointer = Marshal.StringToCoTaskMemUni(aumid) };
      store.SetValue(ref key, ref value);
      store.Commit();
      Marshal.FreeCoTaskMem(value.pointer);
      ((IPersistFile)link).Save(linkPath, true);
    }
  }
}
'@

[ProbeShortcut.Maker]::Create($Target, $Aumid, $LinkPath)
"created: $LinkPath"
