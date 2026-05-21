import re
import os

# =========================================================================
# 1. CONFIGURACIÓN DE RUTAS (Automáticas y Multiplataforma)
# =========================================================================
# Averiguamos la ruta exacta de la carpeta donde se encuentra este script .py
DIRECTORIO_ACTUAL = os.path.dirname(os.path.abspath(__file__))

# Buscamos las plantillas en la misma carpeta donde está el script
RUTA_PLANTILLA_USO = os.path.join(DIRECTORIO_ACTUAL, "tostadora_uso.sci")
RUTA_PLANTILLA_SIM = os.path.join(DIRECTORIO_ACTUAL, "tostadora_sim.sci")

# Creamos la ruta para la nueva subcarpeta "electrodomesticos_creados"
CARPETA_DESTINO = os.path.join(DIRECTORIO_ACTUAL, "electrodomesticos_creados")
# =========================================================================

def generar_bloques_scilab():
    print("=== GENERADOR DE BLOQUES XCOS / SCILAB ===")
    
    # 1. Pedir los datos de nombre y curva 
    nuevo_nombre = input("1. Nombre del nuevo electrodoméstico (ej. Hervidor, Microondas): ").strip()
    
    if not nuevo_nombre:
        print("Error: Debes introducir un nombre.")
        return

    vector_datos = input(f"2. Pega el vector de datos para {nuevo_nombre} (ej. [0, 0; 1, 100; 2, 0]): ").strip()
    
    if not vector_datos.startswith("[") or not vector_datos.endswith("]"):
        print("Advertencia: Asegúrate de incluir los corchetes [ ] en tu vector.")
        
    try:
        # 2. Abrir ambas plantillas
        with open(RUTA_PLANTILLA_USO, 'r', encoding='utf-8') as f_uso:
            contenido_uso = f_uso.read()
            
        with open(RUTA_PLANTILLA_SIM, 'r', encoding='utf-8') as f_sim:
            contenido_sim = f_sim.read()
            
    except FileNotFoundError as e:
        print(f"\n[!] ERROR: No se encuentra una de las plantillas.")
        print(f"Detalle: {e}")
        print("Por favor, asegúrate de que los archivos 'tostadora_uso.sci' y 'tostadora_sim.sci' están en la misma carpeta que este script.")
        return

    # 3. Modificar el archivo de INTERFAZ (_uso.sci)
    # Cambiamos el nombre
    contenido_uso_mod = contenido_uso.replace('tostadora', nuevo_nombre)
    contenido_uso_mod = contenido_uso_mod.replace('Tostadora', nuevo_nombre)

    # Cambiamos el vector curve_def
    patron_vector = r"curve_def\s*=\s*\[.*?\];"
    texto_nuevo_vector = f"curve_def = {vector_datos};"
    contenido_uso_final = re.sub(patron_vector, texto_nuevo_vector, contenido_uso_mod, flags=re.DOTALL)

    # =====================================================================
    # 4. MODIFICAR EL ARCHIVO DE SIMULACIÓN (_sim.sci)
    # =====================================================================
    # A) Cambiamos la palabra general
    contenido_sim_mod = re.sub(r'tostadora', nuevo_nombre, contenido_sim, flags=re.IGNORECASE)
    
    # B) Forzamos matemáticamente el nombre de la función
    # Esto busca "function block = [CualquierCosa]_sim(block, flag)" y lo cambia por tu nombre
    contenido_sim_final = re.sub(r'function block\s*=\s*\w+_sim\(block,\s*flag\)', 
                                 f'function block = {nuevo_nombre}_sim(block, flag)', 
                                 contenido_sim_mod)

    # 5. Guardar los nuevos archivos en la carpeta de destino
    os.makedirs(CARPETA_DESTINO, exist_ok=True)
    
    nombre_archivo_uso = f"{nuevo_nombre}_uso.sci"
    nombre_archivo_sim = f"{nuevo_nombre}_sim.sci"
    
    ruta_salida_uso = os.path.join(CARPETA_DESTINO, nombre_archivo_uso)
    ruta_salida_sim = os.path.join(CARPETA_DESTINO, nombre_archivo_sim)
    
    # Escribir _uso.sci
    with open(ruta_salida_uso, 'w', encoding='utf-8') as f:
        f.write(contenido_uso_final)
        
    # Escribir _sim.sci
    with open(ruta_salida_sim, 'w', encoding='utf-8') as f:
        f.write(contenido_sim_final)
        
    print("\n=======================================================")
    print(f"¡ÉXITO! Se han creado los 2 archivos para: {nuevo_nombre}")
    print(f" -> {ruta_salida_uso}")
    print(f" -> {ruta_salida_sim}")
    print("=======================================================\n")

if __name__ == "__main__":
    generar_bloques_scilab()
