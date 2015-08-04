# Copyright 2015 basebuilder authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

Vagrant.configure("2") do |config|
  config.vm.provider :aws do |aws, override|
    override.vm.box = "dummy"
    override.vm.box_url = "https://raw.githubusercontent.com/mitchellh/vagrant-aws/master/dummy.box"

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = ENV["AWS_PRIVATE_KEY_PATH"]
    override.vm.provision :shell, :inline => <<-SH
        export AWS_ACCESS_KEY=#{ENV["AWS_ACCESS_KEY_ID"]}
        export AWS_SECRET_KEY=#{ENV["AWS_SECRET_ACCESS_KEY"]}
    SH
    override.vm.provision :shell, path: "setup.bash"

    aws.access_key_id = ENV["AWS_ACCESS_KEY_ID"]
    aws.secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
    aws.keypair_name = ENV["AWS_KEYPAIR_NAME"]
    aws.ami = ENV["AWS_AMI"]
    aws.region = ENV["AWS_REGION"]
    aws.instance_type = ENV["AWS_INSTANCE_TYPE"]
    aws.instance_ready_timeout = 300
    aws.block_device_mapping = [{"DeviceName" => "/dev/sda1", "Ebs.VolumeSize" => 60}]
    aws.tags = {
      "Name" => "vagrant_platform_test",
    }
    aws.user_data = "#!/bin/bash\nperl -i -pe 's/^# *(.+)(trusty|trusty-updates|trusty-security) multiverse$/$1$2 multiverse/gi' /etc/apt/sources.list"
  end
end
