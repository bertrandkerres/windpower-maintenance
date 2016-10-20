function InitTurbine (wf, no_t, lifetime) 

    for k=1:no_t
        V44 = WT ('V44', lifetime, k);
        V44.main_service_intervall = 8760/2;
        V44.regular_maintenance_time = 7;
        V44.regular_maintenance_material_cost = 5000;
        V44.power_curve = PowerCurve (pc');

        c_generator = DelayTimeComponent ('Generator', 'wbl', [496751, 0.6832], 'wbl', [7073, 1.3]);
        c_generator.install_time = 16;
        c_generator.inspection_time = 3;
        c_generator.lead_time = 504;
        c_generator.new_cost = 330000;
        c_generator.used_cost = 70000;
        c_generator.change_equipment_cost = 70000;
        c_generator.inspection_interval=1*8760;

        c_electricsystem = InstantFailComponent ('RCC', 'wbl', [134115.9, 0.6434]);
        c_electricsystem.install_time = 5;
        c_electricsystem.inspection_time = 2;
        c_electricsystem.lead_time = 48;
        c_electricsystem.new_cost = 330000;
        c_electricsystem.used_cost = 60000;
        c_electricsystem.change_equipment_cost = 0;

        c_controlsystem = InstantFailComponent ('Control system', 'wbl', [363197.6, 0.8782]);
        c_controlsystem.install_time = 2;
        c_controlsystem.inspection_time = 1;
        c_controlsystem.lead_time = 0;
        c_controlsystem.new_cost = 13000;
        c_controlsystem.used_cost = 3000;
        c_controlsystem.change_equipment_cost = 0;


        c_gearbox = DelayTimeComponent ('Gearbox', 'wbl', [225777, 1.3349], 'wbl', [7073, 1.3]);
        c_gearbox.install_time = 24;
        c_gearbox.inspection_time = 6;
        c_gearbox.lead_time = 672;
        c_gearbox.new_cost = 1000000;
        c_gearbox.used_cost = 80000;
        c_gearbox.change_equipment_cost = 70000;
        c_gearbox.inspection_interval = 1*8760;
        c_gearbox.inspection_age = 10*8760;


        c_hydraulics = InstantFailComponent ('Hydraulic valve', 'wbl', [147705.9, 1.7617]);
        c_hydraulics.install_time = 2;
        c_hydraulics.inspection_time = 1;
        c_hydraulics.lead_time = 0;
        c_hydraulics.new_cost = 17000;
        c_hydraulics.used_cost = 4000;
        c_hydraulics.change_equipment_cost = 0;


        V44.AddComponent (c_generator);
        V44.AddComponent (c_electricsystem);
        V44.AddComponent (c_controlsystem);
        V44.AddComponent (c_gearbox);
        V44.AddComponent (c_hydraulics);
        
        wf.AddTurbine (V44);
    end
end

