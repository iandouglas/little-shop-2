class Order < ApplicationRecord
  validates_presence_of :status

  belongs_to :user
  has_many :order_items
  has_many :items, through: :order_items

  enum status: ['pending', 'packaged', 'shipped', 'cancelled']

  def order_quantity(order_id)
    OrderItem.where(order_id: order_id)
         .sum(:quantity)
  end

  def order_grand_total(order_id)
    OrderItem.where(order_id: order_id)
         .sum("quantity * order_price")
  end

  def merchant_order_total(order)
    Order.joins(:order_items)
         .where(id: order.id)
         .sum("order_items.quantity")
  end

  def merchant_order_total_price(order)
    Order.joins(:order_items)
         .where(id: order.id)
         .sum("order_items.quantity * order_items.order_price")
  end

  def self.largest_3_orders
    Order.joins(:order_items)
         .select("orders.*, sum(order_items.quantity) as total_quantity")
         .group(:id)
         .order("total_quantity DESC")
         .limit(3)
  end

  def change_oi_status(order)
    list_of_ois = Order.find(order.id).order_items
    list_of_ois.each do |oi|
      oi.update(fulfilled: false)
    end
  end

  def restock_items(order)
    list_of_ois = Order.find(order.id).order_items
    list_of_ois.each do |oi|
      oi.item.update(stock: (oi.item.stock += oi.quantity))
    end
  end
end
