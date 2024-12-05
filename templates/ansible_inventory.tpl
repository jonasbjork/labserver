[labservers]
%{ for index, node in droplet_name ~}
${node}.${project_name}.${domain} ansible_host=${droplet_ip[index]}
%{ endfor ~}
