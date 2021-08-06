# pi-rack


## install new PI

Install Ubuntu:
- image SD card with ubuntu 20.04 LTS 64bit using Raspberry Pi Imager
- open SD card in finder
- open "user-data" file in text editor
- add line `hostname: devopsxx` (replacing xx with a increasing/unique number)
- boot pi

Update account:
- ssh into the pi: `ssh ubuntu@192.168.1.xxx` (password ubuntu)
- change password (see [1password](https://start.1password.com/open/i?a=6CBAWYSER5FWNJ4BSPEWJMEI74&v=hdctpdrnvvqbpflqiipgyh3iii&i=4kt3u55vsvhcznktbpoi7xpzeu&h=my.1password.com))
- open new tab in terminal
- run `ssh-copy-id -i ~/.ssh/pi-agents ubuntu@192.168.1.xxx`
- try ssh again; it should not prompt for password

Update OS:
- `sudo apt update`
- `sudo dpkg --configure -a`
- `sudo apt upgrade`
- `sudo apt autoremove`

Install ansible:
- `sudo apt install python3-pip`
- `sudo pip3 install ansible`


# Ansible

https://medium.com/gsoft-tech/easily-configuring-an-azure-devops-agent-with-ansible-fb9cb0f98b73
https://github.com/gsoft-inc/ansible-role-azure-devops-agent



  tasks:
  - name: delete
    file:
      state: absent
      path: "home/az_devops_agent/agent/bin/Agent.Listener"