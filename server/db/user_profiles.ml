module Fwd = Domains.Objects.User_profile

module T = struct
  module UserId = Users.T.Id

  module Nickname = Morph.Hom (struct
      module M = Fwd.Nickname

      let typ = Caqti_type.string
    end)

  module Profile = Morph.Hom (struct
      module M = Fwd.Profile

      let typ = Caqti_type.string
    end)

  module BirthDate = Morph.Iso (struct
      module M = Fwd.BirthDate

      let typ = Caqti_type.int64
    end)
end

let upsert dbh ~user_id ~nickname ~profile ~birth_date =
  let open Utils.Let.Result in
  let* user_id, nickname, profile, birth_date =
    [%rapper
      get_one
        {sql|
          INSERT INTO user_profiles (user_id, nickname, profile, birth_date)
          VALUES (%T.UserId{user_id}, %T.Nickname{nickname}, %T.Profile{profile}, to_timestamp(%T.BirthDate{birth_date}))
          ON CONFLICT (user_id) DO UPDATE
          SET nickname = EXCLUDED.nickname,
              profile = EXCLUDED.profile,
              birth_date = EXCLUDED.birth_date
          RETURNING
            @T.UserId{user_id},
            @T.Nickname{nickname},
            @T.Profile{profile},
            @T.BirthDate{extract(epoch from birth_date)}
        |sql}]
      ~user_id
      ~nickname
      ~profile
      ~birth_date
      dbh
  in
  return @@ Fwd.make ~user_id ~nickname ~profile ~birth_date
;;

let find_by_user_id dbh ~user_id =
  let open Utils.Let.Result in
  let* user_id, nickname, profile, birth_date =
    [%rapper
      get_one
        {sql|
            SELECT
              @T.UserId{user_id},
              @T.Nickname{nickname},
              @T.Profile{profile},
              @T.BirthDate{extract(epoch from birth_date)}
            FROM user_profiles
            WHERE user_id = %T.UserId{user_id}
          |sql}]
      ~user_id
      dbh
  in
  return @@ Fwd.make ~user_id ~nickname ~profile ~birth_date
;;

let list_with_pagination dbh ~limit ~offset =
  let open Utils.Let.Result in
  let* profiles =
    [%rapper
      get_many
        {sql|
            SELECT
              @T.UserId{user_id},
              @T.Nickname{nickname},
              @T.Profile{profile},
              @T.BirthDate{extract(epoch from birth_date)}
            FROM user_profiles
            ORDER BY user_id
            LIMIT %int{limit} OFFSET %int{offset}
          |sql}]
      ~limit
      ~offset
      dbh
  in
  let profiles =
    List.map
      (fun (user_id, nickname, profile, birth_date) ->
         Fwd.make ~user_id ~nickname ~profile ~birth_date)
      profiles
  in
  return profiles
;;
