module RoleModel
  module ClassMethods
    def inherited(subclass) # :nodoc:
      ::RoleModel::INHERITABLE_CLASS_ATTRIBUTES.each do |attribute|
        instance_var = "@#{attribute}"
        subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
      end
      super
    end

    # set the bitmask attribute role assignments will be stored in
    def roles_attribute(name)
      self.roles_attribute = name
    end

    # alternative method signature: set the bitmask attribute role assignments will be stored in
    def roles_attribute=(name)
      self.roles_attribute_name = name.to_sym
    end

    # set the title of public methods using to work with model
    def roles_setter(title)
      self.roles_setter = title
    end

    # alternative method signature: set the title of public methods using to work with model
    def roles_setter=(title)
      self.roles_setter_title = title.to_sym

      # assign roles
      self.send(:define_method, self.roles_setter_title.to_s.concat('=').to_sym) { |*roles|
        self.send("#{self.class.roles_attribute_name}=", self.class.mask_for(*roles))
      }

      # query assigned roles
      self.send(:define_method, self.roles_setter_title) {
        Roles.new(self, self.class.valid_roles.reject { |r| ((self.send(self.class.roles_attribute_name) || 0) & 2**self.class.valid_roles.index(r)).zero? })
      }
    end

    def mask_for(*roles)
      sanitized_roles = roles.map { |role| Array(role) }.flatten.map(&:to_sym)

      (valid_roles & sanitized_roles).inject(0) { |sum, role| sum + 2**valid_roles.index(role) }
    end

    def roles_alias_method(title)
      title.to_s.concat('=').to_sym
    end

    protected

    # :call-seq:
    #   roles(:role_1, ..., :role_n)
    #   roles('role_1', ..., 'role_n')
    #   roles([:role_1, ..., :role_n])
    #   roles(['role_1', ..., 'role_n'])
    #
    # declare valid roles
    def roles(*roles)
      opts = roles.last.is_a?(Hash) ? roles.pop : {}
      self.valid_roles = roles.flatten.map(&:to_sym)
      unless (opts[:dynamic] == false)
        self.define_dynamic_queries(self.valid_roles)
      end
    end

    # Defines dynamic queries for :role
    #   #is_<:role>?
    #   #<:role>?
    #
    # Defines new methods which call #is?(:role)
    def define_dynamic_queries(roles)
      dynamic_module = Module.new do
        roles.each do |role|
          ["#{role}?".to_sym, "is_#{role}?".to_sym].each do |method|
            define_method(method) { is? role }
          end
        end
      end
      include dynamic_module
    end
  end
end
