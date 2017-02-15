class CarrierProfile
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :organization

  # temporary field for importing seed files
  field :hbx_carrier_id, type: Integer

  field :abbrev, type: String
  field :associated_carrier_profile_id, type: BSON::ObjectId

  field :ivl_health, type: Boolean
  field :ivl_dental, type: Boolean
  field :shop_health, type: Boolean
  field :shop_dental, type: Boolean

  field :issuer_hios_id, type: String
  field :issuer_state, type: String, default: "DC"
  field :market_coverage, type: String, default: "shop (small group)" # or individual
  field :dental_only_plan, type: Boolean, default: false


  delegate :hbx_id, to: :organization, allow_nil: true
  delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: false
  delegate :is_active, :is_active=, to: :organization, allow_nil: false
  delegate :updated_by, :updated_by=, to: :organization, allow_nil: false


  def associated_carrier_profile=(new_associated_carrier_profile)
    if new_associated_carrier_profile.present?
      raise ArgumentError.new("expected CarrierProfile") unless new_associated_carrier_profile.is_a? CarrierProfile
      self.associated_carrier_profile_id = new_associated_carrier_profile._id
      new_associated_carrier_profile
    else
      self.associated_carrier_profile_id = nil
    end
  end

  def associated_carrier_profile
    CarrierProfile.find(self.associated_carrier_profile_id) unless self.associated_carrier_profile_id.blank?
  end

  # has_many Plans
  def plans
    Plan.where(carrier_profile_id: self._id)
  end

  ## Class methods
  class << self
    def list_embedded(parent_list)
      parent_list.reduce([]) { |list, parent_instance| list << parent_instance.carrier_profile }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      list_embedded Organization.exists(carrier_profile: true).order_by([:legal_name]).to_a
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      organizations = Organization.where("carrier_profile._id" => BSON::ObjectId.from_string(id.to_s)).to_a
      organizations.size > 0 ? organizations.first.carrier_profile : nil
    end

    def find_by_legal_name(name)
      organizations = Organization.where("legal_name" => name).to_a
      organizations.size > 0 ? organizations.first.carrier_profile._id : ""
    end
  end

end
