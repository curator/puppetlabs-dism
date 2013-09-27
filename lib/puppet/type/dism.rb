Puppet::Type.newtype(:dism) do
  @doc = "Manages Windows features via dism."

  ensurable do
    desc "Windows feature install state."

    defaultvalues

    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end
  end

  newparam(:name, :namevar=>true) do
    desc "The Windows feature name (case-sensitive)."
  end

  newparam(:answer) do
    desc "The answer file for installing the feature."
    newvalues(/[a-zA-Z]:\\/, /\\\\/)
  end

  newparam(:source) do
    desc "Path to source files for feature (optional)"
    newvalues(/[a-zA-Z]:\\/, /\\\\/)
  end

  newparam(:all) do
    desc "Whether or not to install all parental dependencies (Windows 8/2012 only, optional, default: false)"
    newvalues(:true, :false)
    defaultto false
  end

  newparam(:limitaccess) do
    desc "Whether or not to allow dism to connect to Windows Update during install/removal (optional, default: false)"
    newvalues(:true, :false)
    defaultto false
  end

  newparam(:exitcode, :array_matching => :all) do
    desc "DISM installation process exit code (optional)"
    defaultto([0, 3010, 3010 & 0xFF])
  end
end
