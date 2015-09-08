public origin_cure_post_human(id)
{
    set_user_health(id, get_pcvar_num(cvar_human_health_default))
    set_user_gravity(id, HUMAN_GRAVITY)
}
