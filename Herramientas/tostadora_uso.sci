function [x, y, typ] = tostadora_uso(job, arg1, arg2)
  x = []; y = []; typ = [];
  
  // Definimos un tamaño estándar para TODOS los electrodomésticos
  MAX_FILAS = 50; 

  select job
  case 'set' then
    x = arg1; 
    y = 0;
    model = arg1.model;
    graphics = arg1.graphics;
    exprs = graphics.exprs; 
    
    while %t do
      [ok, Ts_new, curve_new, exprs_new] = scicos_getvalue( ..
        'Configuración de la tostadora', ..
        ['Paso de tiempo del reloj (ej. 1 min)'; 'Curva de Carga [Minuto, Potencia]'], ..
        list('vec', 1, 'mat', [-1, 2]), .. 
        exprs);

      if ~ok then break; end
      
      // ---------------------------------------------------------
      // ALGORITMO DE RELLENO AUTOMÁTICO (ZERO-PADDING)
      // ---------------------------------------------------------
      filas_reales = size(curve_new, 1);
      curva_estandar = zeros(MAX_FILAS, 2);
      
      // Copiamos la curva real al principio
      if filas_reales <= MAX_FILAS then
          curva_estandar(1:filas_reales, :) = curve_new;
          
          // Rellenamos el resto. 
          // El tiempo tiene que seguir avanzando para no romper la lógica, 
          // pero la potencia será 0.
          t_final = curve_new($, 1); // El último tiempo de tu curva
          for i = (filas_reales + 1):MAX_FILAS
              curva_estandar(i, 1) = t_final + (i - filas_reales); // Sube 1 min en cada fila extra
              curva_estandar(i, 2) = 0; // 0 Vatios de consumo
          end
      else
          // Si por casualidad metes una curva de más de 50 filas, la recorta
          // (Si necesitas más, sube la variable MAX_FILAS arriba)
          curva_estandar = curve_new(1:MAX_FILAS, :);
      end
      // ---------------------------------------------------------
      
      // Ahora guardamos la curva RELLENADA en lugar de la original
      model.rpar = [Ts_new; curva_estandar(:)];
      
      // El tamaño del puerto 3 ahora siempre es fijo: MAX_FILAS * 2 columnas
      model.out(3) = MAX_FILAS * 2; 
      
      graphics.exprs = exprs_new;
      x.model = model;
      x.graphics = graphics;
      break;
    end
    
  case 'define' then

    // ======================
    // ZONA DE CONFIGURACIÓN
    // ======================
    //tiempo de paso de la simulación
    Ts_def = 1;
    // ======================
    // Vector de curva de carga del electrodoméstico
    
    curve_def = [0.017, 13.8; 0.12, 1714; 5.20, 1686; 5.27, 13.8; 9.29, 13.8; 9.36, 1723; 10.98, 1691; 11.0, 0];
    
    // Hacemos el mismo relleno para los valores por defecto
    filas_reales = size(curve_def, 1);
    curva_estandar = zeros(MAX_FILAS, 2);
    curva_estandar(1:filas_reales, :) = curve_def;
    t_final = curve_def($, 1);
    for i = (filas_reales + 1):MAX_FILAS
        curva_estandar(i, 1) = t_final + (i - filas_reales);
        curva_estandar(i, 2) = 0;
    end
    
    model = scicos_model();
    model.sim = list('tostadora_sim', 5);
    
    model.in = 1;           
    model.intyp = 1;
    
    // La salida 3 siempre tendrá el mismo tamaño: MAX_FILAS * 2
    model.out = [1; 1; MAX_FILAS * 2]; 
    model.out2 = [1; 1; 1];    
    model.outtyp = [1; 1; 1];
    
    model.evtin = 1;   
    model.evtout = 0;
    
    // Pasamos la curva estandarizada a rpar
    model.rpar = [Ts_def; curva_estandar(:)];
    model.dstate = [0; 0];  
    model.blocktype = 'd';
    model.dep_ut = [%t %f]; 
    
    
    //imagen del bloque
    exprs = [sci2exp(Ts_def); sci2exp(curve_def)];
    
    // --- BÚSQUEDA DE IMAGEN ESTANDARIZADA ---
    ruta_base = getenv("Comunidades_Energéticas_Xcos", "");
    // Ajusta la carpeta "png" o "gif" según dónde tengas realmente la imagen tostadora.png
    ruta_imagen = pathconvert(ruta_base + filesep() + "images" + filesep() + "gif" + filesep() + "tostadora_uso.png", %F, %T);
    // Validamos si la imagen existe
    if ~isfile(ruta_imagen) then
        // MODO SIN IMAGEN (Texto por defecto)
        gr_i = ['txt=''Aparato'';xstringb(orig(1),orig(2),txt,sz(1),sz(2),''fill'')'];
        x = standard_define([3 3], model, exprs, gr_i);
    else
        // MODO CON IMAGEN
        gr_i = []; 
        x = standard_define([3 3], model, exprs, gr_i);
        x.graphics.style = "image=file://" + ruta_imagen + ";verticalLabelPosition=bottom";
    end




  case 'plot' then
    standard_draw(arg1);
  end
endfunction
