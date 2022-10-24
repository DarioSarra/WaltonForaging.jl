#= This dictionary translate numbers into the corresponding information:
    values [1,16] are state-info values [17,35] are event-info
=#
const InfoDict = Dict(
    "1"=>"delay_forage_left",
    "2"=>"start_forage_left",
    "3"=>"in_left",
    "4"=>"out_left",
    "5"=>"reward_left_available",
    "6"=>"reward_left",
    "7"=>"reward_consumption_left",
    "8"=>"delay_forage_right",
    "9"=>"start_forage_right",
    "10"=>"in_right",
    "11"=>"out_right",
    "12"=>"reward_right_available",
    "13"=>"reward_right",
    "14"=>"reward_consumption_right",
    "15"=>"travel",
    "16"=>"travel_available",
    "17"=>"poke_4",
    "18"=>"poke_4_out",
    "19"=>"poke_2",
    "20"=>"poke_2_out",
    "21"=>"poke_3",
    "22"=>"poke_3_out",
    "23"=>"poke_6",
    "24" =>"poke_6_out",
    "25"=>"poke_9",
    "26"=>"poke_9_out",
    "27"=>"session_timer",
    "28"=>"forage_timer",
    "29"=>"travel_tone_increment",
    "30"=>"travel_out_of_poke",
    "31"=>"travel_resumed",
    "32"=>"travel_complete",
    "33"=>"task_disengagment",
    "34"=>"post_travel_delay_timer",
    "35"=>"reward_consumption_timer",
    "36"=>"rsync"
)

const PortDict = Dict(
    "poke_2"=>"PokeLeft",
    "poke_4"=>"RewLeft",
    "poke_3"=>"PokeRight",
    "poke_6"=>"RewRight",
    "poke_9"=>"TravPoke"
)

const PortStatusDict = Dict("PokeLeft" => "forage",
    "RewLeft" => "reward",
    "PokeRight" => "forage",
    "RewRight" => "reward",
    "TravPoke" => "travel"
)
