export EmptyRoom

mutable struct EmptyRoom{R} <: AbstractGridWorld
    world::GridWorldBase{Tuple{Empty, Wall, Goal}}
    agent::Agent
    reward::Float64
    rng::R
    terminal_reward::Float64
    goal_pos::CartesianIndex{2}
end

function EmptyRoom(; height = 8, width = 8, rng = Random.GLOBAL_RNG)
    objects = (EMPTY, WALL, GOAL)
    world = GridWorldBase(objects, height, width)
    room = Room(CartesianIndex(1, 1), height, width)
    place_room!(world, room)

    goal_pos = CartesianIndex(height - 1, width - 1)
    world[GOAL, goal_pos] = true
    world[EMPTY, goal_pos] = false

    agent = Agent()
    reward = 0.0
    terminal_reward = 1.0

    env = EmptyRoom(world, agent, reward, rng, terminal_reward, goal_pos)

    reset!(env)

    return env
end

function RLBase.reset!(env::EmptyRoom)
    rng = get_rng(env)

    old_goal_pos = get_goal_pos(env)
    env[GOAL, old_goal_pos] = false
    env[EMPTY, old_goal_pos] = true

    new_goal_pos = rand(rng, pos -> env[EMPTY, pos], env)

    set_goal_pos!(env, new_goal_pos)
    env[GOAL, new_goal_pos] = true
    env[EMPTY, new_goal_pos] = false

    agent_start_pos = rand(rng, pos -> env[EMPTY, pos], env)
    agent_start_dir = rand(rng, DIRECTIONS)

    set_agent_pos!(env, agent_start_pos)
    set_agent_dir!(env, agent_start_dir)

    set_reward!(env, 0.0)

    return env
end
