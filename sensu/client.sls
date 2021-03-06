{% from "sensu/pillar_map.jinja" import sensu with context %}
{% from "sensu/service_map.jinja" import services with context %}
{% from "sensu/configfile_map.jinja" import files with context %}

include:
  - sensu
  - sensu.rabbitmq_conf

{% if grains['os_family'] == 'Windows' %}
/opt/sensu/bin/sensu-client.xml:
  file.managed:
    - source: salt://sensu/files/windows/sensu-client.xml
    - template: jinja
    - require:
      - pkg: sensu
sensu_install_dotnet35:
  cmd.run:
    - name: 'powershell.exe "Import-Module ServerManager;Add-WindowsFeature Net-Framework-Core"'
sensu_enable_windows_service:
  cmd.run:
    - name: 'sc create sensu-client start= delayed-auto binPath= c:\opt\sensu\bin\sensu-client.exe DisplayName= "Sensu Client"'
    - unless: 'sc query sensu-client'
{% endif %}
/etc/sensu/conf.d/client.json:
  file.serialize:
    - formatter: json
    - user: {{files.files.user}}
    - group: {{files.files.group}}
    {% if grains['os_family'] != 'Windows' %}
    - mode: 644
    {% endif %}
    - makedirs: True
    - dataset:
        client:
          name: {{ sensu.client.name }}
          address: {{ sensu.client.address }}
          subscriptions: {{ sensu.client.subscriptions }}
          safe_mode: {{ sensu.client.safe_mode }}
<<<<<<< HEAD
{% if sensu.client.get("command_tokens") %}
          command_tokens: {{ sensu.client.command_tokens }}
{% endif %}
{% if sensu.client.get("redact") %}
          redact: {{ sensu.client.redact }}
{% endif %}
=======
          keepalive: {{ sensu.client.keepalive }}
>>>>>>> 3e357cda916c4c084e832efa3c51cb1b09ca36aa
    - require:
      - pkg: sensu

/etc/sensu/plugins:
  file.recurse:
    - source: salt://{{ sensu.paths.plugins }}
    {% if grains['os_family'] != 'Windows' %}
    - file_mode: 555
    {% endif %}
    - require:
      - pkg: sensu
    - require_in:
      - service: sensu-client
    - watch_in:
      - service: sensu-client

sensu-client:
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/conf.d/client.json
      - file: /etc/sensu/conf.d/rabbitmq.json
    - watch:
      - file: /etc/sensu/conf.d/*

{% if grains['os_family'] != 'Windows' %}
/etc/default/sensu:
  file.replace:
{%- if sensu.client.embedded_ruby %}
    - pattern: 'EMBEDDED_RUBY=false'
    - repl: 'EMBEDDED_RUBY=true'
{%- else %}
    - pattern: 'EMBEDDED_RUBY=true'
    - repl: 'EMBEDDED_RUBY=false'
{%- endif %}
    - watch_in:
      - service: sensu-client
{% endif %}

{% if sensu.client.nagios_plugins %}
{{ services.nagios_plugins }}:
  pkg:
    - installed
    - require_in:
      - service: sensu-client
{% endif %}

{% set gem_list = salt['pillar.get']('sensu:client:install_gems', []) %}
{% for gem in gem_list %}
{% if gem is mapping %}
{% set gem_name = gem.name %}
{% else %}
{% set gem_name = gem %}
{% endif %}
install_{{ gem_name }}:
  gem.installed:
    - name: {{ gem_name }}
    {% if sensu.client.embedded_ruby %}
    - gem_bin: /opt/sensu/embedded/bin/gem
    {% else %}
    - gem_bin: None
    {% endif %}
    {% if gem.version is defined %}
    - version: {{ gem.version }}
    {% endif %}
    - rdoc: False
    - ri: False
{% endfor %}
<<<<<<< HEAD

{%- if salt['pillar.get']('sensu:checks') %}

sensu_checks_file:
  file.serialize:
    - name: {{ sensu.paths.checks_file }}
    - dataset:
        checks: {{ salt['pillar.get']('sensu:checks') }}
    - formatter: json
    - require:
      - pkg: sensu
    - watch_in:
      - service: sensu-client

{%- endif %}
=======
>>>>>>> 3e357cda916c4c084e832efa3c51cb1b09ca36aa
