require "pstore"

class Cfg
   @@default_name = "data/config.pstore"
   def initialize(filename=nil)
      if filename
         @data = PStore.new(filename)
      else
         @data = PStore.new(@@default_name)
         @data.transaction do 
            @data["users"] = []
            @data["port"] = 12345
            @data["name"] = "Unnamed server!"
         end
      end
   end
   def get(name)
      @data.transaction { @data[name] }
   end
   def add_user(name)
      @data.transaction { @data["users"] << name }
   end
end
