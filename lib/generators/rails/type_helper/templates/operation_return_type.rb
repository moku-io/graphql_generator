module Types
  class OperationReturnType < Base::BaseObject
    description 'Generic return type for operations that have no intrinsic return type'

    class OperationReturnTypeEnum < Base::BaseEnum
      value :ok
      value :ko
    end

    field :success, OperationReturnTypeEnum, null: true
  end
end
