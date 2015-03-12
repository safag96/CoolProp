module CoolProp

export F2K, K2F, HAPropsSI, PropsSI, PhaseSI, get_global_param_string, get_param_index, get_input_pair_index, AbstractState_factory, AbstractState_free, AbstractState_update, AbstractState_keyed_output

function F2K(TF::Number)
  return ccall( (:F2K, "CoolProp"), Cdouble, (Cdouble,), TF)
end

function K2F(TK::Number)
  return ccall( (:K2F, "CoolProp"), Cdouble, (Cdouble,), TK)
end

function HAPropsSI(Output::String, Name1::String, Value1::Number, Name2::String, Value2::Number, Name3::String, Value3::Number)
  val = ccall( (:HAPropsSI, "CoolProp"), Cdouble, (Ptr{UInt8},Ptr{UInt8},Float64,Ptr{UInt8},Float64,Ptr{UInt8},Float64), Output,Name1,Value1,Name2,Value2,Name3,Value3)
  if val == Inf
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return val
end

function PropsSI(Output::String, Name1::String, Value1::Number, Name2::String, Value2::Number, Fluid::String)
  val = ccall( (:PropsSI, "CoolProp"), Cdouble, (Ptr{UInt8},Ptr{UInt8},Float64,Ptr{UInt8},Float64,Ptr{UInt8}), Output,Name1,Value1,Name2,Value2,Fluid)
  if val == Inf
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return val
end

function PropsSI(FluidName::String, Output::String)
  val = ccall( (:Props1SI, "CoolProp"), Cdouble, (Ptr{UInt8},Ptr{UInt8}), FluidName,Output)
  if val == Inf
    error("CoolProp: ", get_global_param_string("errstring"))
  end
  return val
end

function PhaseSI(Name1::String, Value1::Number, Name2::String, Value2::Number, Fluid::String)
  outstring = Array(UInt8, 255)
  val = ccall( (:PhaseSI, "CoolProp"), Int32, (Ptr{UInt8},Float64,Ptr{UInt8},Float64,Ptr{UInt8}, Ptr{UInt8}, Int), Name1,Value1,Name2,Value2,Fluid,outstring,length(outstring))
  return bytestring(convert(Ptr{UInt8}, pointer(outstring)))
end

# This function returns the output string in pre-allocated char buffer.  If buffer is not large enough, no copy is made
function get_global_param_string(Key::String)
  Outstring = Array(UInt8, 255)
  val = ccall( (:get_global_param_string, "CoolProp"), Clong, (Ptr{UInt8},Ptr{UInt8},Int), Key,Outstring,length(Outstring))
  return bytestring(convert(Ptr{UInt8}, pointer(Outstring)))
end

# Get the index for a parameter "T", "P", etc.
# returns the index as a long.
function get_param_index(Param::String)
  val = ccall( (:get_param_index, "CoolProp"), Clong, (Ptr{UInt8},), Param)
  if val == -1
    error("CoolProp: Unknown parameter: ", Param)
  end
  return val
end

# Get the index for an input pair for AbstractState.update function
# returns the index as a long.
function get_input_pair_index(Param::String)
  val = ccall( (:get_input_pair_index, "CoolProp"), Clong, (Ptr{UInt8},), Param)
  if val == -1
    error("CoolProp: Unknown input pair: ", Param)
  end
  return val
end

# ---------------------------------
#        Low-level access
# ---------------------------------

errcode = Ref{Clong}(0)
buffer_length = 255
message_buffer = Array(UInt8, buffer_length)

# Generate an AbstractState instance, return an integer handle to the state class generated to be used in the other low-level accessor functions
# param backend The backend you will use, "HEOS", "REFPROP", etc.
# param fluids '&' delimited list of fluids
# return A handle to the state class generated
function AbstractState_factory(backend::String, fluids::String)
  AbstractState = ccall( (:AbstractState_factory, "CoolProp"), Clong, (Ptr{UInt8},Ptr{UInt8},Ref{Clong},Ptr{UInt8},Clong), backend,fluids,errcode,message_buffer,buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", bytestring(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return AbstractState
end

# Release a state class generated by the low-level interface wrapper
# param handle The integer handle for the state class stored in memory
function AbstractState_free(handle::Clong)
  ccall( (:AbstractState_free, "CoolProp"), Void, (Clong,Ref{Clong},Ptr{UInt8},Clong), handle,errcode,message_buffer,buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", bytestring(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

# Set the fractions (mole, mass, volume) for the AbstractState
# param handle The integer handle for the state class stored in memory
# param fractions The array of fractions
function AbstractState_set_fractions(handle::Clong,fractions::Array)
  ccall( (:AbstractState_set_fractions, "CoolProp"), Void, (Clong,Ptr{Cdouble},Clong,Ref{Clong},Ptr{UInt8},Clong), handle,fractions,length(fractions),errcode,message_buffer,buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", bytestring(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

# Update the state of the AbstractState
# param handle The integer handle for the state class stored in memory
# param input_pair The integer value for the input pair obtained from get_input_pair_index(Param::String)
# param value1 The first input value
# param value2 The second input value
function AbstractState_update(handle::Clong,input_pair::Clong,value1::Number,value2::Number)
  ccall( (:AbstractState_update, "CoolProp"), Void, (Clong,Clong,Cdouble,Cdouble,Ref{Clong},Ptr{UInt8},Clong), handle,input_pair,value1,value2,errcode,message_buffer,buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", bytestring(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  end
  return nothing
end

# Get an output value from the AbstractState using an integer value for the desired output value
# param handle The integer handle for the state class stored in memory
# param param The integer value for the parameter you want
function AbstractState_keyed_output(handle::Clong, param::Clong)
  output = ccall( (:AbstractState_keyed_output, "CoolProp"), Cdouble, (Clong,Clong,Ref{Clong},Ptr{UInt8},Clong), handle,param,errcode,message_buffer,buffer_length)
  if errcode[] != 0
    if errcode[] == 1
      error("CoolProp: ", bytestring(convert(Ptr{UInt8}, pointer(message_buffer))))
    elseif errcode[] == 2
      error("CoolProp: message buffer too small")
    else # == 3
      error("CoolProp: unknown error")
    end
  elseif output == -Inf
    error("CoolProp: no correct state has been set with AbstractState_update")
  end
  return output
end

end #module
