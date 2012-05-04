class Carga < ActiveRecord::Base
  # ESTO ES UN COMMIT
  # ESTO ES UN COMMIT 2
  def self.crear(numero, producto, monto)
    Rails.logger.debug "Consultando por #{numero} (#{producto}), $#{monto}"
    carga = Carga.new
    carga.empresa = "create"
    carga.monto = 0
    carga.numero = 0
    carga.save!
    begin
      respuesta = TransactionRouter::Switch.consulta_recarga_electronica!(
        :MONTO => monto, :PRODUCTO => producto, 
        :NUMERO_IDENTIFICACION => producto == "DIRECT TV" ? Rut.cleaner(numero)[0,Rut.cleaner(numero).length] : numero, :VENDEDOR => "72828790", :SECUENCIA_COMERCIO => carga.id
      )
    ensure
      if $!
        Rails.logger.warn "Error de WS: #{$!.message}"
      end
    end

    if respuesta["CODIGO_RESPUESTA"] == "01"
      Rails.logger.debug "Consulta aprobada"
      carga.empresa = producto
      carga.numero = numero
      carga.monto = monto
      carga.estado_pago = nil
      carga.estado_recarga = nil
      carga.codigo_mc = respuesta["CODIGO_MC"]
      carga.save!
      return carga
    else
      carga.destroy
      Rails.logger.debug "Consulta rechazada: '#{respuesta["MENSAJE_RESPUESTA"]}'"
      return nil
    end
  end

end
