{%- for region_name, region_data in salt['pillar.get']('aws:region', {}).items() %}
  {%- set profile = region_data.get('profile')  %}

  {%- for vpc_name, vpc_data in region_data.get('vpc').items() %}

# VPC
aws_vpc_{{ vpc_name }}_create:
  boto_vpc.present:
    {%- for option, value in vpc_data.get('vpc', {}).items() %}
    - {{ option }}: '{{ value }}'
    {%- endfor %}
    - profile: {{ profile }}

# Internet Gateway
aws_vpc_{{ vpc_name }}_create_internet_gateway:
  boto_vpc.internet_gateway_present:
    - name: {{ vpc_data.get('internet_gateway:name', 'internet_gateway') }}
    - vpc_name: {{ vpc_name }}
    - profile: {{ profile }}

# Subnets and NAT Gateways
    {%- for subnet_number, subnet_data in vpc_data.get('subnets', {}).items() %}
aws_vpc_{{ vpc_name }}_create_subnet_{{ subnet_data.name }}:
  boto_vpc.subnet_present:
    - name: {{ subnet_data.name }}
    - vpc_name: {{ vpc_name }}
    - cidr_block: {{ vpc_data.cidr_prefix }}.{{ subnet_number }}.0/24
    - availability_zone: {{ region_name }}{{ subnet_data.az }}
    - profile: {{ profile }}

      {%- if subnet_data.get('nat_gateway', False ) %}
aws_vpc_{{ vpc_name }}_create_nat_gateway_{{ subnet_data.name }}:
  boto_vpc.nat_gateway_present:
    - subnet_name: {{ subnet_data.name }}
    - profile: {{ profile }}
      {%- endif %}
    {% endfor %}

# Create Routing Tables and associate subnets
# ( routes to NAT Gateways currently not supported )
    {%- for table_name, table_data in vpc_data.get('routing_tables', {}).items() %}
aws_vpc_{{ vpc_name }}_create_routing_table_{{ table_name }}:
  boto_vpc.route_table_present:
    - name: {{ table_name }}
    - vpc_name: {{ vpc_name }}
    - profile: {{ profile }}
      {%- if table_data.get('routes', false ) %}
    - routes:
        {%- for route_name, route_data in table_data.get('routes').items() %}
          {%- for option, value in route_data.items() %}
            {%- if loop.first %}
      - {{ option }}: '{{ value }}'
            {%- else %}
        {{ option }}: '{{ value }}'
            {%- endif %}
          {%- endfor %}
        {%- endfor %}
      {%- endif %}

      {%- if table_data.get('subnet_names', false ) %}
    - subnet_names:
        {%- for subnet_name in table_data.subnet_names %}
      - {{ subnet_name }}
        {%- endfor %}
      {%- endif %}
    {% endfor %}
  {% endfor %}
{% endfor %}
