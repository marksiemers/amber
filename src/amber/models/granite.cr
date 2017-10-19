module Amber::Models::Granite
  macro included
	  def initialize
	  end

	  def initialize(args : Hash(String | Symbol, Amber::Router::ParamsType))
        set_attributes(args)
  	  end

	  def set_attributes(args : Hash(Symbol | String, Amber::Router::ParamsType))
        args.each do |k, v|
          cast_to_field(k, v.as(DB::Any))
	    end
	  end
  end
end
