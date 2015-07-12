# -*- coding: utf-8 -*-

"""
Installs and configures Opflex
"""

import sys
from packstack.installer import validators
from packstack.installer import processors
from packstack.installer import utils
from packstack.installer.utils import split_hosts

from packstack.modules.common import filtered_hosts
from packstack.modules.shortcuts import get_mq
from packstack.modules.ospluginutils import (getManifestTemplate,
                                             appendManifestFile,
                                             createFirewallResources)

# ------------- Glance Packstack Plugin Initialization --------------

PLUGIN_NAME = "OS-gbp"
PLUGIN_NAME_COLORED = utils.color_text(PLUGIN_NAME, 'blue')


def initConfig(controller):
    params = [
        {"CMD_OPTION": "apic-host",
         "USAGE": ("The IP address of APIC controller"),
         "PROMPT": "Enter the IP address of the APIC controller",
         "OPTION_LIST": [],
         "VALIDATORS": [validators.validate_not_empty],
         "PROCESSORS": [],
         "DEFAULT_VALUE": "",
         "MASK_INPUT": False,
         "LOOSE_VALIDATION": True,
         "CONF_NAME": "CONFIG_APIC_CONTROLLER",
         "USE_DEFAULT": False,
         "CONDITION": False},

        {"CMD_OPTION": "apic-enable-ssl",
         "USAGE": "Enable SSL for the APIC communication",
         "PROMPT": "Enable SSL for the APIC commnication?",
         "OPTION_LIST": ["y", "n"],
         "VALIDATORS": [validators.validate_options],
         "PROCESSORS": [],
         "DEFAULT_VALUE": "y",
         "MASK_INPUT": False,
         "LOOSE_VALIDATION": False,
         "CONF_NAME": "CONFIG_APIC_ENABLE_SSL",
         "USE_DEFAULT": True,
         "NEED_CONFIRM": False,
         "CONDITION": False},
       
        {"CMD_OPTION": "apic-username",
         "USAGE": "Username for APIC login",
         "PROMPT": "Username for APIC login:",
         "OPTION_LIST": [],
         "VALIDATORS": [validators.validate_not_empty],
         "PROCESSORS": [],
         "DEFAULT_VALUE": "admin",
         "MASK_INPUT": False,
         "LOOSE_VALIDATION": True,
         "CONF_NAME": "CONFIG_APIC_USERNAME",
         "USE_DEFAULT": True,
         "CONDITION": False},
       
        {"CMD_OPTION": "apic-passwd",
         "USAGE": "The password to use to access APIC",
         "PROMPT": "Enter the password for APIC access",
         "OPTION_LIST": [],
         "VALIDATORS": [validators.validate_not_empty],
         "PROCESSORS": [processors.process_password],
         "DEFAULT_VALUE": "",
         "MASK_INPUT": True,
         "LOOSE_VALIDATION": False,
         "CONF_NAME": "CONFIG_APIC_PW",
         "USE_DEFAULT": False,
         "NEED_CONFIRM": True,
         "CONDITION": False},

        {"CMD_OPTION": "apic-infra-vlan",
         "USAGE": "Infra Vlan number configured in APIC",
	 "PROMPT": "APIC infra vlan number:",
         "OPTION_LIST": [],
         "VALIDATORS": [validators.validate_not_empty],
         "PROCESSORS": [],
         "DEFAULT_VALUE": "4093",
         "MASK_INPUT": False,
         "LOOSE_VALIDATION": True,
         "CONF_NAME": "CONFIG_APIC_INFRA_VLAN",
         "USE_DEFAULT": True,
         "CONDITION": False},

        {"CMD_OPTION": "gbp-mode",
         "USAGE": "GBP mode",
         "PROMPT": "GBP mode, valid values (ml2-apicl3-noopflex, ml2-neutronl3-noopflex, ml2-opflex, opflex)?",
         "OPTION_LIST": ["ml2-apicl3-noopflex", "ml2-neutronl3-noopflex", "ml2-opflex", "opflex"],
         "VALIDATORS": [validators.validate_options],
         "PROCESSORS": [],
         "DEFAULT_VALUE": "opflex",
         "MASK_INPUT": False,
         "LOOSE_VALIDATION": False,
         "CONF_NAME": "CONFIG_GBP_MODE",
         "USE_DEFAULT": True,
         "NEED_CONFIRM": False,
         "CONDITION": False},
       
        {"CMD_OPTION": "apic-conn-json",
         "USAGE": ( "String describing the server connections to switches in JSON format"
                    "Example { 301: [f3-compute-1.cisco.com:1/33, f3-compute-2.cisco.com:1/34], 302:[f3-compute-1:1/1] }"
                    "where 301 is the switch id as defined in APIC"
                    "f3-compute-1 is a host connected to port 1/33 of switch with id 301"),
         "PROMPT": "Enter the host<->switch connection in JSON format",
         "OPTION_LIST": [],
         "VALIDATORS": [],
         "PROCESSORS": [],
         "DEFAULT_VALUE": "{}",
         "MASK_INPUT": True,
         "LOOSE_VALIDATION": False,
         "CONF_NAME": "CONFIG_APIC_CONN_JSON",
         "USE_DEFAULT": False,
         "NEED_CONFIRM": True,
         "CONDITION": False},

        {"CMD_OPTION": "apic-extnet-json",
         "USAGE": ( "String describing the external network details in JSON format"
                    "Example { infra: {switch:201, port:1/2, encap:vlan-1200, cidr_exposed:1.1.1.254/24, gateway_ip:1.1.1.1, router_id:1.0.0.1}, outside: {switch:201, port:1/2, encap:vlan-1201, cide_exposed:1.1.2.254/24, gateway_ip:1.1.2.1, router_id:1.0.0.2}} "),
         "PROMPT": "Enter the external network details in JSON format",
         "OPTION_LIST": [],
         "VALIDATORS": [],
         "PROCESSORS": [],
         "DEFAULT_VALUE": "{}",
         "MASK_INPUT": True,
         "LOOSE_VALIDATION": False,
         "CONF_NAME": "CONFIG_APIC_EXTNET_JSON",
         "USE_DEFAULT": False,
         "NEED_CONFIRM": True,
         "CONDITION": False},


    ]
    group = {"GROUP_NAME": "GBP",
             "DESCRIPTION": "GBP Config parameters",
             "PRE_CONDITION": "CONFIG_GBP_INSTALL",
             "PRE_CONDITION_MATCH": "y",
             "POST_CONDITION": False,
             "POST_CONDITION_MATCH": True}
    controller.addGroup(group, params)


def initSequences(controller):
    config = controller.CONF
    if config['CONFIG_HEAT_INSTALL'] != 'y':
        print "GBP requires HEAT to be installed. Please set CONFIG_HEAT_INSTALL to 'y'"
        sys.exit(1)

    if config['CONFIG_GBP_INSTALL'] != 'y':
        return

    global api_hosts, network_hosts, compute_hosts, q_hosts
    api_hosts = split_hosts(config['CONFIG_CONTROLLER_HOST'])
    network_hosts = split_hosts(config['CONFIG_NETWORK_HOSTS'])
    compute_hosts = set()
    compute_hosts = split_hosts(config['CONFIG_COMPUTE_HOSTS'])
    q_hosts = api_hosts | network_hosts | compute_hosts

    gbpsteps = [ ]
    if config['CONFIG_GBP_MODE'] == "opflex":
        gbpsteps = [
            {'title': 'Adding GBP packages installation manifest entries',
             'functions': [opflex_create_gbp_pkgs_install_manifests]},
            {'title': 'Adding GBP neutron configuration manifest entries',
             'functions': [opflex_create_gbp_neutron_config_manifests]},
            {'title': 'Adding GBP nova configuration manifest entries',
             'functions': [create_gbp_nova_config_manifests]},
            {'title': 'Adding GBP UI configuration manifest entries',
             'functions': [create_gbp_ui_manifests]},
        ]

    if config['CONFIG_GBP_MODE'] == "ml2-neutronl3-noopflex":
        gbpsteps = [
            {'title': 'ML2-NL3-NOOPFLEX, Adding GBP packages installation manifest entries',
                'functions': [ml2_nl3_noopflex_create_gbp_pkgs_install_manifests]},   
            {'title': 'ML2-NL3-NOOPFLEX, Adding GBP neutron configuration manifest entries',
                'functions': [ml2_nl3_noopflex_create_gbp_neutron_config_manifests]},
            {'title': 'ML2-NL3-NOOPFLEX Adding GBP nova configuration manifest entries',
             'functions': [ml2_nl3_noopflex_create_gbp_nova_config_manifests]},
            {'title': 'ML2-NL3-NOOPFLEX Adding GBP UI configuration manifest entries',
             'functions': [ml2_nl3_noopflex_create_gbp_ui_manifests]},
        ]
    controller.addSequence("Installing OpenStack GBP", [], [], gbpsteps)


# ------------------------- helper functions -------------------------


# -------------------------- step functions --------------------------

## ML2-NL3-NOOPFLEX functions
def ml2_nl3_noopflex_create_gbp_pkgs_install_manifests(config, messages):
    global api_hosts, network_hosts, compute_hosts, q_hosts

    for qhost in q_hosts:
        manifest_file = "%s_gbp_ml2_nl3_noopflex.pp" % (qhost)
        manifest_data = getManifestTemplate("ml2_nl3_noopflex_pkgs_install")
        appendManifestFile(manifest_file, manifest_data, 'gbp')

def ml2_nl3_noopflex_create_gbp_neutron_config_manifests(config, messages):
    global api_hosts, network_hosts, compute_hosts, q_hosts

    for xhost in api_hosts: 
	manifest_file = "%s_gbp_ml2_nl3_noopflex.pp" % (xhost,)
	manifest_data = getManifestTemplate("ml2_nl3_noopflex_gbp_neutron_conf")
	appendManifestFile(manifest_file, manifest_data, 'gbp')

	manifest_data = getManifestTemplate("ml2_nl3_noopflex_gbp_neutron_ml2_conf")
	appendManifestFile(manifest_file, manifest_data, 'gbp')

	manifest_data = getManifestTemplate("ml2_nl3_noopflex_gbp_neutron_ml2_conf_cisco")
	appendManifestFile(manifest_file, manifest_data, 'gbp')

	manifest_data = getManifestTemplate("ml2_nl3_noopflex_gbp_neutron_nova_api")
	appendManifestFile(manifest_file, manifest_data, 'gbp')

    for xhost in network_hosts:
	manifest_file = "%s_gbp_ml2_nl3_noopflex.pp" % (xhost,)
	manifest_data = getManifestTemplate("ml2_nl3_noopflex_gbp_neutron_dhcp_agent")
	appendManifestFile(manifest_file, manifest_data, 'gbp')


def ml2_nl3_noopflex_create_gbp_nova_config_manifests(config, messages):
    global api_hosts, compute_hosts
    for xhost in compute_hosts:
	manifest_file = "%s_gbp_ml2_nl3_noopflex.pp" % (xhost,)
	manifest_data = getManifestTemplate("ml2_nl3_noopflex_gbp_nova")
	appendManifestFile(manifest_file, manifest_data, "gbp")

def ml2_nl3_noopflex_create_gbp_ui_manifests(config, messages):
    global api_hosts
    for xhost in api_hosts:
	manifest_file = "%s_gbp_ml2_nl3_noopflex.pp" % (xhost,)
	manifest_data = getManifestTemplate("ml2_nl3_noopflex_gbp_automation_ui")
	appendManifestFile(manifest_file, manifest_data, "gbp")

## OPFLEX functions
def opflex_create_gbp_pkgs_install_manifests(config, messages):
    global api_hosts, network_hosts, compute_hosts, q_hosts

    #all common packages for any type of hosts
    for qhost in q_hosts:
	manifest_file = "%s_gbp.pp" % (qhost,)
	manifest_data = getManifestTemplate("gbp_pkgs_install")
	appendManifestFile(manifest_file, manifest_data, 'gbp')

    for xhost in network_hosts | compute_hosts:
	manifest_file = "%s_gbp.pp" % (xhost,)
	manifest_data = getManifestTemplate("gbp_opflex_install")
	appendManifestFile(manifest_file, manifest_data, 'gbp')


def opflex_create_gbp_neutron_config_manifests(config, messages):
    global api_hosts, network_hosts, compute_hosts

    for xhost in api_hosts | network_hosts:
	manifest_file = "%s_gbp.pp" % (xhost,)
	manifest_data = getManifestTemplate("gbp_neutron")
	appendManifestFile(manifest_file, manifest_data, 'gbp')
	if xhost in network_hosts:
	    manifest_data = getManifestTemplate('gbp_neutron_dhcp')
	    appendManifestFile(manifest_file, manifest_data, 'gbp')

    for xhost in network_hosts | compute_hosts:
	manifest_file = "%s_gbp.pp" % (xhost,)
	manifest_data = getManifestTemplate("gbp_neutron_ovs")
	appendManifestFile(manifest_file, manifest_data, "gbp")

    for xhost in api_hosts:
	manifest_file = "%s_gbp.pp" % (xhost,)
        manifest_data = getManifestTemplate("gbp_neutron_ml2")
	appendManifestFile(manifest_file, manifest_data, "gbp")

	manifest_data = getManifestTemplate("gbp_neutron_nova_api")
	appendManifestFile(manifest_file, manifest_data, "gbp")


def create_gbp_nova_config_manifests(config, messages):
    global api_hosts, compute_hosts
    for xhost in compute_hosts:
	manifest_file = "%s_gbp.pp" % (xhost,)
	manifest_data = getManifestTemplate("gbp_nova")
	appendManifestFile(manifest_file, manifest_data, "gbp")

def create_gbp_ui_manifests(config, messages):
    global api_hosts
    for xhost in api_hosts:
	manifest_file = "%s_gbp.pp" % (xhost,)
	manifest_data = getManifestTemplate("gbp_automation_ui")
	appendManifestFile(manifest_file, manifest_data, "gbp")

