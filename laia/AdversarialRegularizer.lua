local AdversarialRegularizer, Parent =
  torch.class('laia.AdversarialRegularizer', 'laia.Regularizer')

function AdversarialRegularizer:__init()
  Parent.__init(self)
  self._opt.adversarial_weight  = 0.0
  self._opt.adversarial_epsilon = 0.7
end

-- loss  = the loss value to regularize
-- model = model being optimized
-- input = input to apply adversarial samples on
-- func  = function that performs a forward/backward pass through the model
--         and returns a loss value
function AdversarialRegularizer:regularize(loss, model, input, func)
  -- Handful variables
  local w = self._opt.adversarial_weight
  local eps = self._opt.adversarial_epsilon
  if w > 0.0 and eps > 0.0 then
    -- This assumes model:getParameters() was called before to flatten the
    -- parameters of the model.
    local _, gradParameters = laia.getFlatParameters(model)
    local gradInput = model:get(1).gradInput
    -- Distort images so that the loss increases the maximum but the
    -- pixel-wise differences do not exceed adversarial_epsilon:
    --   x' = x + eps * sign(gradInput)
    local adv_input = torch.add(input, eps, torch.sign(gradInput))
    -- Scale original gradParameters with 1.0 - adversarial_weight,
    -- and keep a copy of these values, since the next call to func() will
    -- overwrite the values in gradParameters
    local orig_gradParameters = torch.mul(gradParameters, 1 - w)
    -- Backprop pass to get the gradients respect the adversarial images
    -- Note: this updated the gradParameters values
    local adv_loss = func(adv_input)
    -- J_final = (1 - w) * J + w * J_adv
    loss = (1 - w) * loss + (    w) * adv_loss
    -- dJ_final = (1 - w) * dJ_orig + (    w) * dJ_adv
    gradParameters:add(orig_gradParameters, w, gradParameters)
  end
  return loss
end

-- This parameter registers the options in the given parser and when the options
-- are parsed the internal variables are directly updated.
-- Note: observe that the options will not be part of the parsed options, since
-- the action does not register them in result table.
function AdversarialRegularizer:registerOptions(parser)
  parser:option(
    '--adversarial_weight',
    'Weight of the adversarial samples during training', 0.0,
    tonumber)
    :argname('<weight>')
    :overwrite(false)
    :ge(0.0):le(1.0)
    :action(function(_, _, v) self._opt.adversarial_weight = v end)
  parser:option(
    '--adversarial_epsilon',
    'Maximum differences in the adversarial samples', 0.007,
    tonumber)
    :argname('<eps>')
    :overwrite(false)
    :ge(0.0)
    :action(function(_, _, v) self._opt.adversarial_epsilon = v end)
end

function AdversarialRegularizer:checkOptions()
  assert(self._opt.adversarial_weight >= 0 and
         self._opt.adversarial_weight <= 1,
	 ('Adversarial weight must be in range [0,1] (value = %s)'):format(
	   self._opt.adversarial_weight))
  assert(self._opt.adversarial_epsilon >= 0,
	 ('Adversarial epsilon must be >= 0 (value = %s)'):format(
	   self._opt.adversarial_epsilon))
end
