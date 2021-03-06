export DoorKey

mutable struct DoorKey{W<:GridWorldBase, R} <: AbstractGridWorld
    world::W
    agent::Agent
    reward::Float64
    rng::R
    terminal_reward::Float64
    goal_pos::CartesianIndex{2}
    door_pos::CartesianIndex{2}
    key_pos::CartesianIndex{2}
end

function DoorKey(; height = 7, width = 7, rng = Random.GLOBAL_RNG)
    door = Door(:yellow)
    key = Key(:yellow)
    objects = (EMPTY, WALL, GOAL, door, key)
    world = GridWorldBase(objects, height, width)
    room = Room(CartesianIndex(1, 1), height, width)
    place_room!(world, room)

    agent = Agent()
    reward = 0.0
    terminal_reward = 1.0
    goal_pos = CartesianIndex(height - 1, width - 1)
    door_pos = CartesianIndex(2, 3)
    key_pos = CartesianIndex(3, 2)

    env = DoorKey(world, agent, reward, rng, terminal_reward, goal_pos, door_pos, key_pos)

    reset!(env)

    return env
end

RLBase.action_space(env::DoorKey) = (MOVE_FORWARD, TURN_LEFT, TURN_RIGHT, PICK_UP)

function (env::DoorKey)(::MoveForward)
    objects = get_objects(env)
    agent = get_agent(env)

    door = objects[end - 1]
    key = objects[end]

    dir = get_agent_dir(env)
    dest = dir(get_agent_pos(env))

    if env[door, dest]
        if get_inventory(env) === key
            set_agent_pos!(env, dest)
        end
    elseif !env[WALL, dest]
        set_agent_pos!(env, dest)
    end

    set_reward!(env, 0.0)
    if is_terminated(env)
        set_reward!(env, env.terminal_reward)
    end

    return env
end

function (env::DoorKey)(::PickUp)
    objects = get_objects(env)

    key = objects[end]
    agent_pos = get_agent_pos(env)

    if env[key, agent_pos] && isnothing(get_inventory(env))
        env[key, agent_pos] = false
        env[EMPTY, agent_pos] = true
        set_inventory!(env, key)
    end

    return env
end

function RLBase.reset!(env::DoorKey)
    height = get_height(env)
    width = get_width(env)
    rng = get_rng(env)

    objects = get_objects(env)
    door = objects[end - 1]
    key = objects[end]

    env[WALL, 2:height-1, env.door_pos[2]] .= false
    env[door, env.door_pos] = false
    env[EMPTY, 2:height-1, env.door_pos[2]] .= true

    if isnothing(get_inventory(env))
        env[key, env.key_pos] = false
        env[EMPTY, env.key_pos] = true
    end

    old_goal_pos = get_goal_pos(env)
    env[GOAL, old_goal_pos] = false
    env[EMPTY, old_goal_pos] = true

    new_door_pos = rand(rng, CartesianIndices((2:height-1, 3:width-2)))
    env.door_pos = new_door_pos
    env[door, new_door_pos] = true
    env[WALL, 2:height-1, new_door_pos[2]] .= true
    env[WALL, new_door_pos] = false
    env[EMPTY, 2:height-1, new_door_pos[2]] .= false

    left_region = CartesianIndices((2:height-1, 2:new_door_pos[2]-1))
    right_region = CartesianIndices((2:height-1, new_door_pos[2]+1:width-1))

    new_goal_pos = rand(rng, pos -> env[EMPTY, pos], right_region)
    set_goal_pos!(env, new_goal_pos)
    env[GOAL, new_goal_pos] = true
    env[EMPTY, new_goal_pos] = false

    new_key_pos = rand(rng, pos -> env[EMPTY, pos], left_region)
    env.key_pos = new_key_pos
    env[key, new_key_pos] = true
    env[EMPTY, new_key_pos] = false

    agent_start_pos = rand(rng, pos -> env[EMPTY, pos], left_region)
    agent_start_dir = rand(rng, DIRECTIONS)

    set_agent_pos!(env, agent_start_pos)
    set_agent_dir!(env, agent_start_dir)
    set_inventory!(env, nothing)

    set_reward!(env, 0.0)

    return env
end
