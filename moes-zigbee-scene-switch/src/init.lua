local OnOff = (require "st.zigbee.zcl.clusters").OnOff
local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"

local button_cmd_handler = function(driver, device, zb_msg)
  local additional_fields = {
    state_change = true
  }
  local body = zb_msg.body.zcl_body.body_bytes:byte()
  local event = nil
  if body == 0x00 then
    event = capabilities.button.button.pushed(additional_fields)
  elseif body == 0x01 then
    event = capabilities.button.button.double(additional_fields)
  elseif body == 0x02 then
    event = capabilities.button.button.held(additional_fields)
  end
  if event ~= nil then
    device:emit_event_for_endpoint(
      zb_msg.address_header.src_endpoint.value,
      event
    )
    if device:get_component_id_for_endpoint(
      zb_msg.address_header.src_endpoint.value
    ) ~= "main" then
      device:emit_event(event)
    end
  end
end

local component_to_endpoint_map = function(device, component)
  local endpoint = nil
  if component == "button1" then
    endpoint = 1
  elseif component == "button2" then
    endpoint = 2
  elseif component == "button3" then
    endpoint = 3
  elseif component == "button4" then
    endpoint = 4
  end
  return endpoint
end

local endpoint_to_component_map = function(device, endpoint)
  return string.format("button%d", endpoint)
end

local device_init = function(driver, device, event)
  for comp_id, comp in pairs(device.profile.components) do
    if device:get_latest_state(comp_id, capabilities.button.ID, capabilities.button.supportedButtonValues.ID) == nil then
      device:emit_component_event(comp, capabilities.button.supportedButtonValues({"pushed","held","double"}, {visibility = { displayed = false }}))
    end
  end
  device:set_component_to_endpoint_fn(component_to_endpoint_map)
  device:set_endpoint_to_component_fn(endpoint_to_component_map)
end

local zigbee_scene_controller_driver_template = {
  supported_capabilities = {
    capabilities.button,
    capabilities.battery
  },
  zigbee_handlers = {
    cluster = {
      [OnOff.ID] = {
        [0xFD] = button_cmd_handler
      }
    }
  },
  lifecycle_handlers = {
    init = device_init
  }
}

defaults.register_for_default_handlers(
  zigbee_scene_controller_driver_template,
  zigbee_scene_controller_driver_template.supported_capabilities
)

local zigbee_scene_controller = ZigbeeDriver(
  "moes-zigbee-scene-controller",
  zigbee_scene_controller_driver_template
)

zigbee_scene_controller:run()
