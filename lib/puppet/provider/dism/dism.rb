Puppet::Type.type(:dism).provide(:dism) do
  @doc = "Manages Windows features for Windows 2008R2 and Windows 7"

  confine :operatingsystem => :windows
  defaultfor :operatingsystem => :windows

  commands :dism =>
               if File.exists? ("#{ENV['SYSTEMROOT']}\\sysnative\\Dism.exe")
                 "#{ENV['SYSTEMROOT']}\\sysnative\\Dism.exe"
               elsif  File.exists? ("#{ENV['SYSTEMROOT']}\\system32\\Dism.exe")
                 "#{ENV['SYSTEMROOT']}\\system32\\Dism.exe"
               else
                 'dism.exe'
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
    command_args = ['/online', '/NoRestart', '/Enable-Feature']
    if resource[:answer] and resource[:all]
      command_args += ['/All', "/FeatureName:#{resource[:name]}", "/Apply-Unattend:#{resource[:answer]}"]
    elsif resource[:answer]
      command_args += ["/FeatureName:#{resource[:name]}", "/Apply-Unattend:#{resource[:answer]}"]
    elsif resource[:all]
      command_args += ['/All', "/FeatureName:#{resource[:name]}"]
    else
      command_args += ["/FeatureName:#{resource[:name]}"]
    end

    if resource[:limitaccess]
      command_args += ['/limitaccess']
    end

    output = execute([command(:dism)]+command_args, :failonfail => false)
    raise Puppet::Error, "Unexpected exitcode: #{$?.exitstatus}\nError:#{output}" unless resource[:exitcode].include? $?.exitstatus

  end

  def destroy
    dism(['/online', '/Disable-Feature', "/FeatureName:#{resource[:name]}"])
  end

  def currentstate
    feature = dism(['/online', '/Get-FeatureInfo', "/FeatureName:#{resource[:name]}"])
    feature =~ /^State : (\w+)/
    $1
  end

  def exists?
    status = @property_hash[:state] || currentstate
    status == 'Enabled'
  end
end
