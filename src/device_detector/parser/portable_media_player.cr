module DeviceDetector::Parser
  struct PortableMediaPlayer
    include Helper

    getter kind = "portable_media_player"
    @@media_players = Hash(String, SingleModelPlayer | MultiModelPlayer).from_yaml(Storage.get("portable_media_player.yml"))

    def initialize(user_agent : String)
      @user_agent = user_agent
    end

    struct SingleModelPlayer
      include YAML::Serializable

      property regex : String
      property device : String?
      property model : String
    end

    struct MultiModelPlayer
      include YAML::Serializable

      property regex : String
      property device : String
      property models : Array(SingleModelPlayer)
    end

    def media_players
      return @@media_players if @@media_players
      @@media_players = Hash(String, SingleModelPlayer | MultiModelPlayer).from_yaml(Storage.get("portable_media_player.yml"))
    end

    def call
      detected_player = {"vendor" => "", "model" => ""}
      media_players.each do |item|
        vendor = item[0]
        device = item[1]

        # --> If device has many models
        if device.is_a?(MultiModelPlayer)
          if Regex.new(device.regex) =~ @user_agent
            device.models.each do |model|
              if Regex.new(model.regex, Setting::REGEX_OPTS) =~ @user_agent
                # Fill known keys
                detected_player.merge!({"vendor" => vendor})
                # If model name contains capture groups
                if capture_groups?(model.model)
                  model_name = fill_groups(model.model, model.regex, @user_agent)
                  detected_player.merge!({"model" => model_name})
                else
                  detected_player.merge!({"model" => model.model})
                end
              end
            end
          end
        end

        # --> If device has one model
        if device.is_a?(SingleModelPlayer)
          if Regex.new(device.regex) =~ @user_agent
            # Fill known keys
            detected_player.merge!({"vendor" => vendor})
            # If model name contains capture groups
            if capture_groups?(device.model)
              model = fill_groups(device.model, device.regex, @user_agent)
              detected_player.merge!({"model" => model})
            else
              detected_player.merge!({"model" => device.model})
            end
          end
        end
      end
      detected_player
    end
  end
end
