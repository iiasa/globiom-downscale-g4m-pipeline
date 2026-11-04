SCENARIOS = {
    ("ssp1", "rcpref"): 0,
    ("ssp1", "rcp60"): 1,
    ("ssp1", "rcp45"): 2,
    ("ssp1", "rcp37"): 3,
    ("ssp1", "rcp26"): 4,
    ("ssp1", "rcp20"): 5,
    ("ssp1", "rcp19"): 6,
    ("ssp1", "rcp18"): 7,
    ("ssp2", "rcpref"): 8,
    ("ssp2", "rcp60"): 9,
    ("ssp2", "rcp45"): 10,
    ("ssp2", "rcp37"): 11,
    ("ssp2", "rcp26"): 12,
    ("ssp2", "rcp20"): 13,
    ("ssp2", "rcp19"): 14,
    ("ssp2", "rcp18"): 15,
    ("ssp3", "rcpref"): 16,
    ("ssp3", "rcp60"): 17,
    ("ssp3", "rcp45"): 18,
    ("ssp3", "rcp37"): 19,
    ("ssp3", "rcp26"): 20,
    ("ssp4", "rcpref"): 21,
    ("ssp4", "rcp60"): 22,
    ("ssp4", "rcp45"): 23,
    ("ssp4", "rcp37"): 24,
    ("ssp4", "rcp26"): 25,
    ("ssp4", "rcp20"): 26,
    ("ssp4", "rcp19"): 27,
    ("ssp4", "rcp18"): 28,
    ("ssp5", "rcpref"): 29,
    ("ssp5", "rcp60"): 30,
    ("ssp5", "rcp45"): 31,
    ("ssp5", "rcp37"): 32,
    ("ssp5", "rcp26"): 33,
}

DOWNSCALING_SCEN3 = {
    "rcpref": "scenRCPref",
    "rcp60": "scenRCP6p0",
    "rcp45": "scenRCP4p5",
    "rcp37": "scenRCP3p7",
    "rcp26": "scenRCP2p6",
    "rcp20": "scenRCP2p0",
    "rcp19": "scenRCP1p9",
    "rcp18": "scenRCP1p8",
}


def resolve_scenario(ssp: object, rcp: object) -> tuple[str, str, int]:
    if not isinstance(ssp, str) or not isinstance(rcp, str):
        raise ValueError("scenario must contain string fields 'ssp' and 'rcp'")

    scenario = (ssp.strip().lower(), rcp.strip().lower())
    try:
        nsim = SCENARIOS[scenario]
    except KeyError:
        supported_rcps = ", ".join(
            supported_rcp
            for supported_ssp, supported_rcp in SCENARIOS
            if supported_ssp == scenario[0]
        )
        if supported_rcps:
            detail = f"Supported RCPs for {scenario[0]}: {supported_rcps}"
        else:
            detail = "Supported SSPs: ssp1, ssp2, ssp3, ssp4, ssp5"
        raise ValueError(
            f"Unsupported GLOBIOM scenario: {scenario[0]}+{scenario[1]}. {detail}"
        ) from None

    return scenario[0], scenario[1], nsim


def resolve_downscaling_tuple(ssp: str, rcp: str) -> tuple[str, str, str]:
    scenario = (ssp.strip().lower(), rcp.strip().lower())
    if scenario not in SCENARIOS:
        raise ValueError(f"Unsupported GLOBIOM scenario: {ssp}+{rcp}")
    return scenario[0].upper(), "SCEN", DOWNSCALING_SCEN3[scenario[1]]
