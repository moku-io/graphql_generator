require_relative 'graphql_model_helper'

class Rails::TypeHelperGenerator < Rails::Generators::NamedBase
  # TODO: check for graphql dependencies - see https://guides.rubyonrails.org/generators.html#gem
  # The methods defined here are executed sequentially

  source_root File.expand_path('templates', __dir__)

  class_option :no_type, type: :boolean, default: false, desc: 'Skip types generation'
  class_option :no_policy, type: :boolean, default: false, desc: 'Skip policy generation'
  class_option :no_input, type: :boolean, default: false, desc: 'Skip input generation'
  class_option :no_mutations, type: :boolean, default: false, desc: 'Skip mutations generation'
  class_option :no_dependencies, type: :boolean, default: false, desc: 'Skip dependencies generation'

  def get_model
    @model = class_name.singularize.classify.constantize
    @model.connection
    @model
  rescue NameError
    if yes?("Model implementation for class: '#{class_name}' not found! Generate empty type anyway?")
      create_type_file
      exit
    else
      exit 0
    end
  end

  def prepare_converter
    @converter = GraphqlModelHelper.new(@model)
  end

  def create_type_file
    return if options['no_type']

    create_file "app/graphql/types/#{file_name}_type.rb", <<~FILE
      module Types
        class #{class_name}Type < Base::BaseObject
          #{@converter.fields.join("\n\t\t")}
        end
      end
    FILE
  end

  def create_input_file
    return if options['no_input']

    create_file "app/graphql/types/inputs/#{file_name}_input.rb", <<~FILE
      module Types
        module Inputs
          class #{class_name}Input < Base::BaseInputObject
            #{@converter.arguments.join("\n\t\t\t")}
          end
        end
      end
    FILE
  end

  def create_create_create_mutation_file
    return if options['no_mutations']

    resolver_head = options['no_policy'] ? '' : "Pundit.authorize(current_user, #{class_name}, :create?)"

    create_file "app/graphql/mutations/#{file_name}_mutations/#{file_name}_create.rb", <<~FILE
      module Mutations
        module #{class_name}Mutations
          class #{class_name}Create < Base::BaseMutation
            argument :input, Types::Inputs::#{class_name}Input, required: true

            type Types::#{class_name}Type

            def resolve(input:)
              #{resolver_head}
              #{class_name}.create!(input.to_h)
            end
          end
        end
      end
    FILE
  end

  def create_update_mutation_file
    return if options['no_mutations']

    resolver_head = options['no_policy'] ? "#{file_name} = #{class_name}.find(#{file_name}_id)" \
                    : "#{file_name} = Pundit.authorize(current_user, #{class_name}.find(#{file_name}_id), :update?)"

    create_file "app/graphql/mutations/#{file_name}_mutations/#{file_name}_update.rb", <<~FILE
      module Mutations
        module #{class_name}Mutations
          class #{class_name}Update < Base::BaseMutation
            argument :#{file_name}_id, ID, required: true
            argument :input, Types::Inputs::#{class_name}Input, required: true

            type Types::#{class_name}Type

            def resolve(#{file_name}_id:, input:)
              #{resolver_head}
              #{file_name}.update!(input.to_h)
              #{file_name}
            end
          end
        end
      end
    FILE
  end

  def create_delete_mutation_file
    return if options['no_mutations']

    resolver_head = options['no_policy'] ? "#{file_name} = #{class_name}.find(#{file_name}_id)" \
                    : "#{file_name} = Pundit.authorize(current_user, #{class_name}.find(#{file_name}_id), :delete?)"

    create_file "app/graphql/mutations/#{file_name}_mutations/#{file_name}_delete.rb", <<~FILE
      module Mutations
        module #{class_name}Mutations
          class #{class_name}Delete < Base::BaseMutation
            argument :#{file_name}_id, ID, required: true

            type Types::OperationReturnType

            def resolve(#{file_name}_id:)
              #{resolver_head}
              #{file_name}.destroy!
              {
                  success: 'ok'
              }
            end
          end
        end
      end
    FILE
  end

  def create_policy_file
    return if options['no_policy']

    create_file "app/policies/#{file_name}_policy.rb", <<~FILE
      class #{class_name}Policy < ApplicationPolicy
        # TODO implement

        def create?
          false
        end

        def update?
          false
        end

        def delete?
          false
        end

      end
    FILE
  end

  def get_dependencies
    @dependencies = @converter.dependencies
    puts "\nFound dependencies: #{@dependencies}"
  end

  def generate_dependencies
    return if options['no_dependencies']

    @dependencies.each do |dependency|
      d_file_name = dependency.tableize.singularize
      # check type
      missing_type = !File.exist?("app/graphql/types/#{d_file_name}_type.rb")
      # check policy
      missing_policy = !File.exist?("app/policies/#{d_file_name}_policy.rb")
      # check input
      missing_input = !File.exist?("app/graphql/types/inputs/#{d_file_name}_input.rb")
      # check mutations
      missing_mutations = !File.exist?("app/graphql/mutations/#{d_file_name}_mutations/#{d_file_name}_create.rb") \
         || !File.exist?("app/graphql/mutations/#{d_file_name}_mutations/#{d_file_name}_update.rb") \
         || !File.exist?("app/graphql/mutations/#{d_file_name}_mutations/#{d_file_name}_delete.rb")

      if missing_type || missing_policy || missing_input || missing_mutations
        if yes?("Found unresolved dependency for: #{dependency}. Do you want to generate it?")
          args = dependency.to_s + @options.map { |k, v| " --#{k} #{v}" }.join
          generate :type_helper, args
        end
      else
        puts "Mutations dependency '#{dependency}' already satisfied. Run 'rails generate type_helper #{dependency}' to overwrite it."
      end
    end
  end

  def check_application_policy
    return if options['no_policy'] || options['no_dependencies']

    unless File.exist?('app/policies/application_policy.rb')
      if yes? "The generated policies are based on the base class ApplicationPolicy and it seems you don't have it in your project. Do you want to generate it?"
        copy_file 'application_policy.rb', 'app/policies/application_policy.rb'
      end
    end
  end

  def check_operations_return_type
    return if options['no_mutations'] || options['no_dependencies']

    unless File.exist?('app/graphql/types/operation_return_type.rb')
      if yes? "The generated delete mutations are based on the class OperationReturnType and it seems you don't have it in your project. Do you want to generate it?"
        copy_file 'operation_return_type.rb', 'app/graphql/types/operation_return_type.rb'
      end
    end
  end
end
