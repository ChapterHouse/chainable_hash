require "chainable_hash/version"

require 'delegate'

class ChainableHash < Hash

  [:to_h, :select].each { |name| instance_variable_set("@super_#{name}".to_sym, instance_method(name)) }
  [:has_key?].each { |name| instance_variable_set("@super_#{name[0..-2]}_predicate".to_sym, instance_method(name)) }

  instance_methods.each do |m|
    undef_method(m) unless m =~ /(^__|^nil\?|^send$|^object_id$)/
  end

  def initialize(*args)
    super
  end

  # TODO: Refactor once the tests are better
  def [](key)
    hash = to_h
    if hash.has_key?(key)
      hash[key]
    else
      default(key)
    end
  end

  def []=(key, value)
    key_set(key)
    super
  end

  def assoc(obj)
    if super_has_key?(object)
      super
    else
      down_chain.assoc(obj)
    end
  end

  def chain_to(hash)
    unless hash == self
      self.down_chain = hash
      down_chain.up_chain_to(self)
    end
  end

  def clear
    deleted_keys += (down_chain.keys - noninheritable)
    deleted_keys.uniq!
    super
  end

  def compare_by_identity
    raise NotImplementedError, "Probably will never be implemented as it allows for children to cause side effects in other children."
  end

  def delete(key)
    if noninheritable?(key)
      super
    else
      if deleted?(key)
        block_given? ? yield(key) : default
      else
        if super_has_key?(key)
          super
        elsif down_chain.has_key?(key)
          delete_key(key)
          down_chain[key]
        else
          block_given? ? yield(key) : default
        end
      end
    end

  end

  def delete_if
    if block_given?
      each { |key, value| delete(key) if yield(key, value) }
      self
    else
      raise NotImplementedError, "External iterator not yet supported"
    end
  end

  def dont_inherit(key)
    noninheritable << key
    noninheritable.uniq!
  end

  def fetch(*args)
    if args.length < 1 || args.length > 2
      raise ArgumentError, "wrong number of arguments (#{args.length} for 1..2)"
    elsif args.length == 2 && block_given?
      warn('warning: block supersedes default value argument')
    end

    hash = to_h
    if hash.has_key?(args.first)
      hash.fetch(args.first)
    else
      if block_given?
        yield(args.first)
      elsif args.length == 2
        args[1]
      else
        raise KeyError, "key not found #{args.first.inspect}"
      end
    end
  end

  def inherit(key)
    noninheritable.delete(key)
  end

  def keep_if
    if block_given?
      each { |key, value| delete(key) unless yield(key, value) }
      self
    else
      raise NotImplementedError, "External iterator not yet supported"
    end
  end

  def respond_to?(*args)
    [:inherit, :dont_inherit].include?(args.first) || {}.respond_to?(*args)
  end

  def to_h
    down_chain.to_h.select { |key, _| inheritable?(key) }.merge(super_to_h).select { |key, _| !deleted?(key) }
  end

  protected

  attr_writer :down_chain, :up_chains

  def key_set(key)
    if inheritable?(key)
      deleted_keys.delete(key)
      #deleted(key).delete
      up_chains.each { |up_chain| up_chain.key_set(key) }
    end
  end

  def up_chain_to(hash)
    unless hash == self
      up_chains << hash
      up_chains.uniq!
    end
  end

  private

  def deleted?(key)
    deleted_keys.include?(key)
    #(deleted.keys + deleted_keys).include?(key)
  end

  def delete_key(key)
    deleted_keys << key
    deleted_keys.uniq!
  end

  # Inherited values we are pretending to have 'deleted' but may be restored if the down_chain sets another value.
  def deleted_keys
    @deleted_keys ||= []
  end

  def down_chain
    @down_chain ||= {}
  end

  def inheritable?(key)
    !noninheritable?(key)
  end

  def noninheritable
    @noninheritable ||= []
  end

  def noninheritable?(key)
    noninheritable.include?(key)
  end

  def method_missing(method_name, *args)
    meth_name = method_name.to_s
    if meth_name[0..5] == "super_"
      iv = meth_name[-1..-1] == "?" ? "@#{meth_name[0..-2]}_predicate".to_sym : "@#{meth_name}".to_sym
      puts iv
      if klass.instance_variable_defined?(iv)
        klass.class_eval <<-super_X
          define_method(:#{meth_name}) do |*args|
            klass.instance_variable_get(:#{iv}).bind(self).(*args)
          end
        super_X
        send(meth_name, *args)
      else
        to_h.send(*(args.unshift(method_name)))
      end
    else
      to_h.send(*(args.unshift(method_name)))
    end
  end

  def up_chains
    @up_chains ||= []
  end


  class_eval <<-def_klass
    define_method(:klass) do
      #{self}
    end
  def_klass


end

a = ChainableHash.new

a[:a] = 1
a[:b] = 2
a[:c] = 3

b = ChainableHash.new
b[:d] = 4
b[:e] = 5

b.chain_to(a)

puts a.inspect
puts b.inspect

puts "---"



#
#puts b[:a]
#puts b[:b]
#puts b[:c]
#puts b[:d]
#puts b[:e]

#b.dont_inherit(:b)
#b[:c] = 7
b.delete(:a)

puts a.inspect
puts b.inspect

puts "---"

a[:b] = 7

puts a.inspect
puts b.inspect

a[:a] = 10

puts "---"
puts a.inspect
puts b.inspect

b[:a] = -1
puts "---"
puts a.inspect
puts b.inspect









class ChainableHash
  # Your code goes here...
end
