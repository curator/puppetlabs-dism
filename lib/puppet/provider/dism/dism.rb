Puppet::Type.type(:dism).provide(:dism) do
  @doc = "Manages Windows features for Windows 2008R2 and Windows 7"

  confine    :operatingsystem => :windows
  defaultfor :operatingsystem => :windows

  if Puppet.features.microsoft_windows?
    if ENV.has_key?('ProgramFiles(x86)')
      commands :dism => "#{Dir::WINDOWS}\\sysnative\\Dism.exe"
    else
      commands :dism => "#{Dir::WINDOWS}\\system32\\Dism.exe"
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.instances
    features = dism '/online', '/Get-Features'
    features = features.scan(/^Feature Name : ([\w-]+)\nState : (\w+)/)
    features.collect do |f|
      new(:name => f[0], :state => f[1])
    end
  end

  def flush
    @property_hash.clear
  end

  def create
    if ENV.has_key?('ProgramFiles(x86)')
      dism_cmd = "#{Dir::WINDOWS}\\sysnative\\Dism.exe"
    else
      dism_cmd = "#{Dir::WINDOWS}\\system32\\Dism.exe"
    end

    base_dism = [
      dism_cmd,
      '/online',
      '/Enable-Feature',
      '/NoRestart'
    ]

    execution_string = base_dism + [ "/FeatureName:#{resource[:name]}" ]

    if resource[:answer]
      execution_string = execution_string + [ "/Apply-Unattend:#{resource[:answer]}" ]
    end
    if resource[:source]
      execution_string = execution_string + [ "/Source:#{resource[:source]}" ]
    end
    if resource[:all]
      execution_string = execution_string + [ "/all" ]
    end

    output = execute(execution_string, :failonfail => false)
    raise Puppet::Error, "Unexpected exitcode: #{$?.exitstatus}\nError:#{output}" unless resource[:exitcode].include? $?.exitstatus
  end

  def destroy
    if ENV.has_key?('ProgramFiles(x86)')
      dism_cmd = "#{Dir::WINDOWS}\\sysnative\\Dism.exe"
    else
      dism_cmd = "#{Dir::WINDOWS}\\system32\\Dism.exe"
    end
    output = execute([dism_cmd, '/online', '/Disable-Feature', "/FeatureName:#{resource[:name]}", '/NoRestart'], :failonfail => false)
    raise Puppet::Error, "Unexpected exitcode: #{$?.exitstatus}\nError:#{output}" unless resource[:exitcode].include? $?.exitstatus
  end

  def currentstate
    feature = dism '/online', '/Get-FeatureInfo', "/FeatureName:#{resource[:name]}"
    feature =~ /^State : (\w+)/
    $1
  end

  def exists?
    status = @property_hash[:state] || currentstate
    status == 'Enabled'
  end
end
