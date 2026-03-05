class ApplicationMailbox < ActionMailbox::Base
  routing(/school@mg\.pyrch\.ai/i => :school_communications)
end
