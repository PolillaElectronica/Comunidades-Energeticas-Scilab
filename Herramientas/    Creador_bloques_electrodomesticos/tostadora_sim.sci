function block = tostadora_sim(block, flag)
  Ts = block.rpar(1);
  curve_data = matrix(block.rpar(2:$), -1, 2);

  // -----------------------------------------------------------
  // FLAG 1: CALCULAR LAS SALIDAS
  // -----------------------------------------------------------
  if flag == 1 then 
    // SALIDA 2: El estado del aparato (1 = ejecutando, 0 = apagado)
    block.outptr(2) = block.z(1);

    // SALIDA 1: La potencia consumida actual
    if block.z(1) == 0 then
      block.outptr(1) = 0;
    else
      t_elapsed = block.z(2);
      potencia_actual = 0;
      for i = 1:size(curve_data, 1)
        if t_elapsed >= curve_data(i, 1) then
          potencia_actual = curve_data(i, 2);
        end
      end
      block.outptr(1) = potencia_actual;
    end
    
    // ¡NUEVO! SALIDA 3: Pasa toda la curva de carga rellenada de golpe al Gestor
    // block.rpar(2:$) ya contiene la matriz de 50 filas gracias al nuevo GUI
    block.outptr(3) = block.rpar(2:$); 

  // -----------------------------------------------------------
  // FLAG 2: ACTUALIZAR ESTADOS (Cronómetro y encendido)
  // -----------------------------------------------------------
  elseif flag == 2 then 
    // La orden de arranque.
    trigger = block.inptr(1); 
    duracion_total = curve_data($, 1); // Como la rellenamos, la última fila siempre tiene el t_final correcto o mayor

    if block.z(1) == 0 then
      // Si está apagado y recibe un 1, arranca sí o sí.
      if trigger >= 0.5 then 
        block.z(1) = 1; 
        block.z(2) = 0;
      end
    else 
      // Si ya está encendido, el cronómetro avanza sí o sí hasta terminar.
      block.z(2) = block.z(2) + Ts; 
      
      // Buscamos el verdadero final útil de la curva (cuando la potencia ya se queda en 0)
      // Para evitar que se quede "encendido" contando los ceros del relleno
      fin_real = 0;
      for i = 1:size(curve_data, 1)
          if curve_data(i, 2) > 0 then
              fin_real = curve_data(i, 1);
          end
      end
      
      if block.z(2) > fin_real then
        block.z(1) = 0;
        block.z(2) = 0; 
      end
    end
  end
endfunction
